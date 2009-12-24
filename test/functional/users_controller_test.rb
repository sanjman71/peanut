require 'test/test_helper'

class UsersControllerTest < ActionController::TestCase

  # Don't have the patience to test all these routes:
  # map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }

  should_route :get, '/providers/new',          :controller => 'users', :action => 'new', :role => 'company provider'
  should_route :post, '/providers/create',      :controller => 'users', :action => 'create', :role => 'company provider'
  should_route :get, '/providers/1/edit',       :controller => 'users', :action => 'edit', :role => 'company provider', :id => "1"
  should_route :put, '/providers/1',            :controller => 'users', :action => 'update', :role => 'company provider', :id => "1"
  should_route :get, '/customers/new',          :controller => 'users', :action => 'new', :role => 'company customer'
  should_route :post, '/customers/create',      :controller => 'users', :action => 'create', :role => 'company customer'
  should_route :get, '/customers/1/edit',       :controller => 'users', :action => 'edit', :role => 'company customer', :id => "1"
  should_route :put, '/customers/1',            :controller => 'users', :action => 'update', :role => 'company customer', :id => "1"

  should_route :get, '/users/1/edit',           :controller => 'users', :action => 'edit', :id => "1"
  should_route :get, '/users/1/sudo',           :controller => 'users', :action => 'sudo', :id => "1"
  should_route :get, '/users/1/add_rpx',        :controller => 'users', :action => 'add_rpx', :id => "1"
  should_route :put, '/users/1/grant_provider', :controller => 'users', :action => 'grant_provider', :id => "1"
  should_route :put, '/users/1/revoke_provider',:controller => 'users', :action => 'revoke_provider', :id => "1"

  context 'invite url with subdomain' do
    setup do
      SubdomainFu.stubs(:subdomain_from).with(anything).returns('peanut')
    end

    # user invite route
    should_route :get,  '/invite/12345', :controller => 'users', :action => 'new', :invitation_token => '12345'
  end

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner          = Factory(:user, :name => "Owner")
    @provider       = Factory(:user, :name => "Provider")
    @provider_email = @provider.email_addresses.create(:address => "provider@walnut.com")
    @customer       = Factory(:user, :name => "Customer", :password => 'customer', :password_confirmation => 'customer')
    @customer_email = @customer.email_addresses.create(:address => "customer@walnut.com")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    # make owner the company manager
    @owner.grant_role('company manager', @company)
    @provider.grant_role('company provider', @provider)
    # add company providers
    @company.user_providers.push(@owner)
    @company.user_providers.push(@provider)
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
  end

  context "new customer" do
    context "without 'create users' privilege" do
      setup do
        get :new, :role => 'company provider'
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
    
    context "with 'create users' privilege" do
      setup do
        # create user as owner
        @controller.stubs(:current_user).returns(@owner)
        get :new, :role => 'company customer'
      end

      should_assign_to(:user)
      should_not_assign_to(:invitation)
      should_assign_to(:role) {'company customer'}

      should_respond_with :success
      should_render_template 'users/new.html.haml'

      should "have required user name text field" do
        assert_select "input#user_name.required", 1
      end

      should "have optional user email text field," do
        assert_select "input#user_email", 1
        assert_select "input#user_email.required", 0
      end

      should "have required user password, and password confirmation text fields" do
        assert_select "input#user_password.required", 1
        assert_select "input#user_password_confirmation.required", 1
      end
    end

    context "with 'return_to' param" do
      setup do
        # create user as owner
        @controller.stubs(:current_user).returns(@owner)
        get :new, :role => 'company customer', :return_to => "/appointments/services/1/confirmation"
      end

      should "set session return_to value" do
        assert_equal "/appointments/services/1/confirmation", session[:return_to]
      end

      should_respond_with :success
      should_render_template 'users/new.html.haml'
    end
  end
  
  context "new provider" do
    context "without 'create users' privilege" do
      context "and no invitation" do
        setup do
          get :new, :role => 'company provider'
        end

        should_respond_with :redirect
        should_redirect_to('unauthorized_path') { unauthorized_path }
      end

      context "and an invalid invitation" do
        setup do
          get :new, :role => 'company provider', :invitation_token => "0"
        end

        should_respond_with :redirect
        should_redirect_to('unauthorized_path') { unauthorized_path }
      end

      context "and a valid provider invitation" do
        setup do
          @sender           = Factory(:user)
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company, :role => 'company provider')
          assert @invitation.valid?
          # stub current user as nobody logged in
          @controller.stubs(:current_user).returns(nil)
          get :new, :invitation_token => @invitation.token, :role => 'company provider'
        end

        should_change("User.count", :by => 1) { User.count } # for the sender user object
        should_change("Invitation.count", :by => 1) { Invitation.count }

        should_not_assign_to :error_message
        should_assign_to(:user)
        should_assign_to(:invitation)
        should_assign_to(:role) {'company provider'}

        should "build new user, but should not create the new user" do
          assert_equal [@recipient_email], assigns(:user).email_addresses.collect(&:address)
        end

        should_respond_with :success
        should_render_template 'users/new.html.haml'
      end
    end
    
    context "with 'create users' privilege" do
      context "and no invitation" do
        setup do
          # create user as owner
          @controller.stubs(:current_user).returns(@owner)
          get :new, :role => 'company provider'
        end

        should_not_change("User.count") { User.count }

        should_not_assign_to(:error_message)
        should_assign_to(:role) {"company provider"}

        should_respond_with :success
        should_render_template 'users/new.html.haml'
      end

      context "and an invalid invitation" do
        setup do
          get :new, :role => 'company provider', :invitation_token => "0"
        end

        should_respond_with :redirect
        should_redirect_to('unauthorized_path') { unauthorized_path }
      end
    end
  end

  context "create provider" do
    context "without 'create users' privilege" do
      context "and no invitation" do
        setup do
          post :create, {:role => 'company provider'}
        end

        should_respond_with :redirect
        should_redirect_to('unauthorized_path') { unauthorized_path }
      end
      
      context "and an invalid invitation" do
        setup do
          post :create, {:role => 'company provider', :invitation_token => "0"}
        end
  
        should_respond_with :redirect
        should_redirect_to('unauthorized_path') { unauthorized_path }
      end
      
      context "and a valid provider invitation and valid user properties as an anonymous user" do
        setup do
          @sender           = Factory(:user)
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company, :role => 'company provider')
          assert @invitation.valid?
          # stub current user as nobody
          @controller.stubs(:current_user).returns(nil)
          ActionView::Base.any_instance.stubs(:current_user).returns(nil)
          post :create, {:invitation_token => @invitation.token, 
                         :role => 'company provider',
                         :user => {:email_addresses_attributes => [{:address => @recipient_email}],
                                   :name => "Invited User", :password => 'secret', :password_confirmation => 'secret'}}
          # reload objects
          @invitation.reload
          @company.reload
        end
  
        should_respond_with :redirect
        should_redirect_to('root path') {"http://test.host/"}
  
        # +1 for the sender user and +1 for the new user
        should_change("User.count", :by => 2) { User.count }
        
        should_assign_to(:invitation) {@invitation}
        should_assign_to :user
        should_assign_to(:role) {"company provider"}
  
        should "add user as a company provider" do
          @user = User.with_email(@recipient_email).first
          assert @company.has_provider?(@user)
        end
        
        should "add company to user's provided_companies" do
          @user = User.with_email(@recipient_email).first
          assert_equal [@company], @user.provided_companies
        end
  
        should "add provider role on company to user" do
          @user = User.with_email(@recipient_email).first
          assert_equal ['company provider'], @user.roles_on(@company).collect(&:name).sort
        end
  
        should "add 'user manager' role on user to user" do
          @user = User.with_email(@recipient_email).first
          assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
        end
  
        should "have updated invitation's recipient to the new user" do
          @user = User.with_email(@recipient_email).first
          assert_equal @user, @invitation.recipient
        end
      end
      
      context "and with a valid customer invitation and valid user properties as an anonymous user" do
        setup do
          @sender           = Factory(:user)
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company, :role => 'company customer')
          assert @invitation.valid?
          # stub current user as nobody
          @controller.stubs(:current_user).returns(nil)
          ActionView::Base.any_instance.stubs(:current_user).returns(nil)
          post :create, {:invitation_token => @invitation.token, 
                         :role => 'company provider',
                         :user => {:email_addresses_attributes => [{:address => @recipient_email}],
                                   :name => "Invited User", :password => 'secret', :password_confirmation => 'secret'}}
          # reload objects
          @invitation.reload
          @company.reload
        end
  
        should_respond_with :redirect
        should_redirect_to('root path') {"http://test.host/"}
  
        # +1 for the sender user and +1 for the new user
        should_change("User.count", :by => 2) { User.count }
        
        should_assign_to(:invitation) {@invitation}
        should_assign_to :user
        should_assign_to(:role) {"company customer"}
      
        should "add 'company customer' role on company to user" do
          @user = User.with_email(@recipient_email).first
          assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
        end
  
        should "add 'user manager' role on user to user" do
          @user = User.with_email(@recipient_email).first
          assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
        end
  
        should "have updated invitation's recipient to the new user" do
          assert_equal assigns(:user), @invitation.recipient
        end
      end
    end
  
    context "with 'create users' privilege" do
      context "and valid user properties and no invitation, as an authenticated user" do
        setup do
          # stub current user as company owner
          @controller.stubs(:current_user).returns(@owner)
          # create user should generate a password
          post :create, {:role => 'company provider',
                         :creator => 'user',
                         :user => {:email_addresses_attributes => [{:address => "sanjay@jarna.com"}], :name => "Sanjay Kapoor"}}
        end

        should_change("User.count", :by => 1) { User.count }
        
        should_assign_to(:creator) {"user"}
        should_assign_to :user
        should_assign_to(:role) {"company provider"}
        should_not_assign_to :invitation

        should "have a valid user" do
          assert assigns(:user).valid?
        end

        should "add user as a company provider" do
          @user = User.with_email("sanjay@jarna.com").first
          assert @company.has_provider?(@user)
        end

        should "add 'company provider' role on company to user" do
          @user = User.with_email("sanjay@jarna.com").first
          assert_equal ['company provider'], @user.roles_on(@company).collect(&:name).sort
        end

        should "add 'user manager' role on user to user" do
          @user = User.with_email("sanjay@jarna.com").first
          assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
        end

        should_respond_with :redirect
        should_redirect_to('providers_path') { providers_path }

        should_set_the_flash_to /Provider Sanjay Kapoor was successfully created/i
      end
    end
  end
  
  context "create customer" do
    context "as guest user" do
      context "for a public company" do
        setup do
          # stub current user as nobody
          @controller.stubs(:current_user).returns(nil)
          post :create, {:role => 'company customer',
                         :creator => 'anonymous',
                         :user => {:email_addresses_attributes => [{:address => 'sanjay@walnut.com'}],
                                   :name => "Sanjay Kapoor", :password => "secret", :password_confirmation => 'secret'}}
        end

        should_change("User.count", :by => 1) { User.count }

        should_assign_to(:creator) {"anonymous"}
        should_assign_to(:user)
        should_assign_to(:role) {"company customer"}
        should_not_assign_to :invitation
  
        should "add 'company customer' role on company to user" do
          @user = User.with_email("sanjay@walnut.com").first
          assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
        end
  
        should "add 'user manager' role on user to user" do
          @user = User.with_email("sanjay@walnut.com").first
          assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
        end
  
        should "not add user as a company provider" do
          @user = User.with_email("sanjay@walnut.com").first
          assert_equal [], @user.provided_companies
        end

        should_redirect_to('root path') {"/"}
        should_set_the_flash_to /Your account was successfully created/i
      end
      
      context "for a private company" do
        setup do
          # private company
          @company.preferences[:public] = 0
          @company.save
          # stub current user as nobody
          @controller.stubs(:current_user).returns(nil)
          post :create, {:role => 'company customer',
                         :creator => 'anonymous',
                         :user => {:email_addresses_attributes => [{:address => 'sanjay@walnut.com'}],
                                   :name => "Sanjay Kapoor", :password => "secret", :password_confirmation => 'secret'}}
        end

        should_not_assign_to(:user)
        should_not_change("User.count") { User.count }

        should_redirect_to('root path') {"/"}
        should_set_the_flash_to /You are not authorized to create a user account for this company/i
      end
    end
  
    context "as an authenticated user, with an email address" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        # create user should generate a password
        post :create, {:role => 'company customer',
                       :creator => 'user',
                       :user => {:email_addresses_attributes => [{:address => "joe@jarna.com"}], :name => "Joe Bloggs"}}
      end

      should_change("User.count", :by => 1) { User.count }

      should_assign_to(:creator) {"user"}
      should_assign_to(:user)
      should_assign_to(:role) {"company customer"}
      should_not_assign_to :invitation

      should "add 'company customer' role on company to user" do
        @user = User.with_email("joe@jarna.com").first
        assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
      end

      should "add 'user manager' role on user to user" do
        @user = User.with_email("joe@jarna.com").first
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end

      should "not add user as a company provider" do
        assert_equal [], assigns(:user).provided_companies
      end

      should_respond_with :redirect
      should_redirect_to('customers_path') { customers_path }

      should_set_the_flash_to /Customer Joe Bloggs was successfully created/i
    end
    
    context "as authenticated user, without an email address" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        # create user should generate a password
        post :create, {:role => 'company customer',
                       :creator => 'user',
                       :user => {:name => "Joe Bloggs"}}
      end

      should_change("User.count", :by => 1) { User.count }

      should_assign_to(:creator) {"user"}
      should_assign_to(:user)
      should_assign_to(:role) {"company customer"}
      should_not_assign_to :invitation

      should "add 'company customer' role on company to user" do
        @user = User.find_by_name("Joe Bloggs")
        assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
      end

      should "add 'user manager' role on user to user" do
        @user = User.find_by_name("Joe Bloggs")
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end

      should "not add user as a company provider" do
        assert_equal [], assigns(:user).provided_companies
      end

      should_respond_with :redirect
      should_redirect_to('customers_path') { customers_path }

      should_set_the_flash_to /Customer Joe Bloggs was successfully created/i
    end
  end
  
  context "edit provider" do
    context "as guest" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        get :edit, :id => @owner.id, :role => 'company provider'
      end
    
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "without 'update users' privilege" do
      setup do
        @user = Factory(:user, :name => "User")
        @controller.stubs(:current_user).returns(@user)
        get :edit, :id => @owner.id, :role => 'company provider'
      end

      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end

    context "with 'update users' privilege as provider" do
      setup do
        @controller.stubs(:current_user).returns(@provider)
        get :edit, :id => @provider.id, :role => 'company provider'
      end

      should_assign_to(:index_path) {"/providers"}

      should "show 'add existing login' link" do
        assert_select "a#add_rpx", 1
      end

      # should "not show 'reset password' link" do
      #   assert_select "a#manager_reset_password", 0
      # end

      should_respond_with :success
      should_render_template "users/edit.html.haml"
    end

    context "with 'update users' privilege as manager" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :edit, :id => @provider.id, :role => 'company provider'
      end

      should_assign_to(:index_path) {"/providers"}

      should "not show 'add existing login' link" do
        assert_select "a#add_rpx", 0
      end

      # should "show 'reset password' link" do
      #   assert_select "a#manager_reset_password", 1
      # end

      should_respond_with :success
      should_render_template "users/edit.html.haml"
    end
  end
  
  context "update provider" do
    context "as nobody" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        put :update, :id => @owner.id, :user => {:name => "Provider Chg"}, :role => 'company provider'
      end
    
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "without 'update users' privilege" do
      setup do
        @user = Factory(:user, :name => "User")
        @controller.stubs(:current_user).returns(@user)
        put :update, :id => @owner.id, :user => {:name => "Provider Chg"}, :role => 'company provider'
      end
  
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "with 'update users' privilege" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        put :update, :id => @owner.id, :user => {:name => "Provider Chg"}, :role => 'company provider'
      end
    
      should_respond_with :redirect
      should_redirect_to('/providers') { "/providers" }
    end
  end
  
  context "edit customer" do
    context "as nobody" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        get :edit, :id => @customer.id, :role => 'company customer'
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "without 'update users' privilege" do
      setup do
        @user = Factory(:user, :name => "User")
        @controller.stubs(:current_user).returns(@user)
        get :edit, :id => @customer.id, :role => 'company customer'
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "with 'update users' privilege" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :edit, :id => @customer.id, :role => 'company customer'
      end

      should_respond_with :success
      should_render_template "users/edit.html.haml"

      should_assign_to(:index_path) { openings_path }
    end
  end
  
  context "update customer" do
    context "as nobody" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        put :update, :id => @customer.id, :user => {:name => "Customer Chg"}, :role => 'company customer'
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "without 'update users' privilege" do
      setup do
        @user = Factory(:user, :name => "User")
        @controller.stubs(:current_user).returns(@user)
        put :update, :id => @customer.id, :user => {:name => "Customer Chg"}, :role => 'company customer'
      end
  
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end

    context "with 'update users' privilege" do
      context "and change name" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          put :update, :id => @customer.id, :role => 'company customer', :user => {:name => "Customer Chg", :password => '', :password_confirmation => ''}
        end

        should "change name" do
          customer = User.with_email(@customer_email.address).first
          assert_equal "Customer Chg", customer.name
        end

        should "not change password" do
          customer = User.with_email(@customer_email.address).first
          assert User.authenticate(customer.email_address, 'customer')
        end

        should_redirect_to("openings path") { openings_path }
      end

      context "and change password" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          put :update, :id => @customer.id, :role => 'company customer', :user => {:password => "secret", :password_confirmation => "secret"}
        end

        should "change password" do
          customer = User.with_email(@customer_email.address).first
          assert User.authenticate(customer.email_address, 'secret')
        end

        should_redirect_to("openings path") { openings_path }
      end

      context "and change email" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          @email = @customer.primary_email_address
          put :update, :id => @customer.id, :role => 'company customer', :user => {:email_addresses_attributes => {"0" => {:address => "anyone@walnut.com", :id => @email.id}}}
        end
        
        should "change email" do
          @customer.reload
          assert_equal "anyone@walnut.com", @customer.primary_email_address.address
          assert_equal "anyone@walnut.com", @customer.email_address
        end
      end

      context "and add phone number" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          put :update, :id => @customer.id, :role => 'company customer', :user => {:phone_numbers_attributes => {"1" => {:address => "650-123-9999", :name => "Mobile"}}}
        end
        
        should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }
        
        should "add user phone number" do
          assert_equal ["6501239999"], @customer.phone_numbers.collect(&:address)
        end
      end
    end
  end

  context "sudo" do
    context "without 'manage site' privilege" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :sudo, :id => @owner.id
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end

    context "with 'manage site' privilege" do
      setup do
        @request.env['HTTP_REFERER'] = 'http://test.com/users'
        @owner.grant_role('admin')
        @controller.stubs(:current_user).returns(@owner)
        get :sudo, :id => @customer.id
      end

      should_assign_to(:sudo_user) { @customer}

      should_redirect_to('referer path') { 'http://test.com/users' }
    end
  end

  context "add rpx" do
    setup do
      @user = Factory(:user, :name => "User")
    end

    context "as guest" do
      setup do
        get :add_rpx, :id => @user.id
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end

    context "as user" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        get :add_rpx, :id => @user.id
      end

      should_respond_with :success
      should_render_template 'users/add_rpx.html.haml'
    end

    context "as manager" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :add_rpx, :id => @user.id
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  end
  
end
