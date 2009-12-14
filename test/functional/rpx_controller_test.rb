require 'test/test_helper'

class RpxControllerTest < ActionController::TestCase

  should_route :get,  '/rpx/customer', :controller => 'rpx', :action => 'customer'

  context "rpx customer" do
    context "create customer using rpx token" do
      context "with email and id" do
        setup do
          # stub RPXNow
          @rpx_hash = {:name=>'sanjman71',:email=>'sanjman71@gmail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
          RPXNow.stubs(:user_data).returns(@rpx_hash)
          get :customer, :token => '12345'
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
      end

      context "with id and no email" do
        setup do
          # stub RPXNow
          @rpx_hash = {:name=>'sanjman71',:email=>nil,:username=>'SanjayKapoor',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
          RPXNow.stubs(:user_data).returns(@rpx_hash)
          get :customer, :token => '12345'
        end

        should_assign_to :data
        should_assign_to :user

        should "create valid user" do
          assert_true assigns(:user).valid?
          assert_equal "sanjman71", assigns(:user).name
        end

        should_change("User.count", :by => 1) { User.count }
      end
    end
    
    # context "login using rpx token" do
    # end
  end
end