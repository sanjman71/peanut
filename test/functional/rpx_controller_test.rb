require 'test/test_helper'

class RpxControllerTest < ActionController::TestCase

  should_route :get,  '/rpx/login', :controller => 'rpx', :action => 'login'

  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
  end

  context "rpx" do
    context "with no data" do
      setup do
        # stub RPXNow
        @rpx_hash = {:name=>'sanjman71',:email=>'sanjman71@gmail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
        RPXNow.stubs(:user_data).returns(nil)
        get :login, :token => '12345'
      end

      should_not_assign_to :data
      should_not_assign_to :user

      should_redirect_to("login path") { "/login" }
    end

    context "create user using rpx token" do
      context "for a private company" do
        setup do
          # private company
          @company.preferences[:public] = 0
          @company.save
          @controller.stubs(:current_company).returns(@company)
          # stub RPXNow
          @rpx_hash = {:name=>'sanjman71',:email=>'sanjman71@gmail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
          RPXNow.stubs(:user_data).returns(@rpx_hash)
          get :login, :token => '12345'
        end

        should_assign_to :data
        should_not_assign_to :user

        should_redirect_to("login path") { "/login" }
        should_set_the_flash_to /You are not authorized to create a user account for this company/i
      end

      context "with id and email" do
        setup do
          # stub RPXNow
          @rpx_hash = {:name=>'sanjman71',:email=>'sanjman71@gmail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
          RPXNow.stubs(:user_data).returns(@rpx_hash)
          get :login, :token => '12345'
        end

        should_assign_to :data
        should_assign_to :user

        should "create valid user" do
          assert_true assigns(:user).valid?
        end

        should_change("User.count", :by => 1) { User.count }

        should "assign user's email identifier" do
          @user = User.with_email("sanjman71@gmail.com").first
          @email_address = @user.primary_email_address
          assert_equal 'https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM', @email_address.identifier
        end

        should_redirect_to("root path") { "/" }
      end

      context "with id but no email" do
        setup do
          # stub RPXNow
          @rpx_hash = {:name=>'sanjman71',:email=>nil,:username=>'SanjayKapoor',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
          RPXNow.stubs(:user_data).returns(@rpx_hash)
          get :login, :token => '12345'
        end

        should_assign_to :data
        should_assign_to :user

        should "create valid user" do
          assert_true assigns(:user).valid?
          assert_equal "sanjman71", assigns(:user).name
        end

        should_change("User.count", :by => 1) { User.count }

        should_redirect_to("root path") { "/" }
      end
    end
    
    # context "login using rpx token" do
    # end
  end
end