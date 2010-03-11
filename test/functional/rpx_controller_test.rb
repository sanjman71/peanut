require 'test/test_helper'

class RpxControllerTest < ActionController::TestCase

  should_route :get,  '/rpx/login', :controller => 'rpx', :action => 'login'
  should_route :get,  '/rpx/add/1', :controller => 'rpx', :action => 'add', :id => '1'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    @user         = Factory(:user, :name => 'Sanjay')
    @email        = @user.email_addresses.create(:address => 'sanjay@walnutindustries.com')
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
  end

  context "login" do
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

    context "with rpx token for a new user" do
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

        should_not_change("User.count") { User.count }

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

        should_change("User.count", :by => 1) { User.count }
        should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

        should "create user in active state" do
          @user = User.with_email("sanjman71@gmail.com").first
          assert_equal 'active', @user.state
        end

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

        should_change("User.count", :by => 1) { User.count }
        should_not_change("EmailAddress.count") { EmailAddress.count }

        should "create user in active state" do
          @user = User.find(assigns(:user).id)
          assert_equal 'active', @user.state
        end

        should "assign user name" do
          @user = User.find(assigns(:user).id)
          assert_equal "sanjman71", @user.name
        end

        should_redirect_to("root path") { "/" }
      end

      context "with id, for a company that requires customer phone numbers" do
        setup do
          @company.preferences[:customer_phone] = 'required'
          @company.save
          # stub RPXNow
          @rpx_hash = {:name=>'sanjman71',:email=>nil,:username=>'SanjayKapoor',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
          RPXNow.stubs(:user_data).returns(@rpx_hash)
          get :login, :token => '12345'
        end

        should_assign_to :data
        should_assign_to :user

        should_change("User.count", :by => 1) { User.count }
        should_not_change("EmailAddress.count") { EmailAddress.count }

        should "create user in incomplete state" do
          @user = User.find(assigns(:user).id)
          assert_equal 'incomplete', @user.state
        end

        should "assign user name" do
          @user = User.find(assigns(:user).id)
          assert_equal "sanjman71", @user.name
        end

        should_redirect_to("root path") { "/" }
      end
    end
    
    context "with rpx token for an existing user" do
      context "with default return_to" do
        setup do
          @rpx_hash = {:identifier=>'12345'}
          RPXNow.stubs(:user_data).returns(@rpx_hash)
          # add email identifier
          @email.update_attribute(:identifier, '12345')
          get :login, :token => 'tokenxyz'
        end
      
        should_assign_to(:data)
        should_assign_to(:user) { @user }
        should_not_assign_to(:return_to)

        should_not_change("User.count") { User.count }
        should_not_change("EmailAddress.count") { EmailAddress.count }

        should_redirect_to("root path") { "/" }
      end
      
      context "with return_to" do
        setup do
          @rpx_hash = {:identifier=>'12345'}
          RPXNow.stubs(:user_data).returns(@rpx_hash)
          # add email identifier
          @email.update_attribute(:identifier, '12345')
          get :login, :token => 'tokenxyz', :return_to => "/users/#{@user.id}/edit"
        end
      
        should_assign_to(:data)
        should_assign_to(:user) { @user }
        should_assign_to(:return_to) { "/users/#{@user.id}/edit" }

        should_not_change("User.count") { User.count }
        should_not_change("EmailAddress.count") { EmailAddress.count }

        should_redirect_to("return_to path") { "/users/#{@user.id}/edit" }
      end
    end
  end
  
  context "add" do
    context "as guest" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        get :add, :token => '12345', :id => @user.id
      end

      should_not_change("User.count") { User.count }
      should_not_change("EmailAddress.count") { EmailAddress.count }

      should_redirect_to("unauthorized path") { "/unauthorized" }
    end

    context "as manager" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :add, :token => '12345', :id => @user.id
      end

      should_not_change("User.count") { User.count }
      should_not_change("EmailAddress.count") { EmailAddress.count }

      should_redirect_to("unauthorized path") { "/unauthorized" }
    end

    context "to user account with 1 rpx account" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        # stub RPXNow
        @rpx_hash = {:name=>'sanjman71',:email=>'sanjman71@gmail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
        RPXNow.stubs(:user_data).returns(@rpx_hash)
        get :add, :token => '12345', :id => @user.id
      end

      should_not_change("User.count") { User.count }
      should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

      should "add email address to user" do
        assert_equal 2, @user.reload.email_addresses.size
        assert_equal 2, @user.reload.email_addresses_count
      end

      should "mark email as verified" do
        @email = @user.email_addresses.with_address('sanjman71@gmail.com').first
        assert_equal 'verified', @email.state
      end

      should "set email prioriy to 2" do
        @email = @user.email_addresses.with_address('sanjman71@gmail.com').first
        assert_equal 2, @email.priority
      end
      
      should_redirect_to("user add rpx path") { "/users/#{@user.id}/add_rpx" }
      should_set_the_flash_to /Added rpx login to your user account/i
    end
  end

end