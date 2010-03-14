require 'test/test_helper'

class UsersControllerTest < ActionController::TestCase

  # Don't have the patience to test all these routes:
  # map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }

  should_route :get, '/staffs/new',          :controller => 'users', :action => 'new', :role => 'company staff'
  should_route :post, '/staffs/create',      :controller => 'users', :action => 'create', :role => 'company staff'
  should_route :get, '/staffs/1/edit',       :controller => 'users', :action => 'edit', :role => 'company staff', :id => "1"
  should_route :put, '/staffs/1',            :controller => 'users', :action => 'update', :role => 'company staff', :id => "1"

  should_route :get, '/customers/new',          :controller => 'users', :action => 'new', :role => 'company customer'
  should_route :post, '/customers/create',      :controller => 'users', :action => 'create', :role => 'company customer'
  should_route :get, '/customers/1/edit',       :controller => 'users', :action => 'edit', :role => 'company customer', :id => "1"
  should_route :put, '/customers/1',            :controller => 'users', :action => 'update', :role => 'company customer', :id => "1"

  should_route :get, '/users/1/edit',           :controller => 'users', :action => 'edit', :id => "1"
  should_route :get, '/users/1/sudo',           :controller => 'users', :action => 'sudo', :id => "1"
  should_route :get, '/users/1/add_rpx',        :controller => 'users', :action => 'add_rpx', :id => "1"
  should_route :put, '/users/1/grant/provider', :controller => 'users', :action => 'grant', :id => "1", :role => 'provider'
  should_route :put, '/users/1/revoke/provider',:controller => 'users', :action => 'revoke', :id => "1", :role => 'provider'

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
    @owner          = Factory(:user, :name => "Joe Owner")
    @owner_email    = @owner.email_addresses.create(:address => "owner@walnut.com")
    @owner_phone    = @owner.phone_numbers.create(:address => "9999999999", :name => "Mobile")
    @provider       = Factory(:user, :name => "Fred Provider")
    @provider_email = @provider.email_addresses.create(:address => "provider@walnut.com")
    @customer       = Factory(:user, :name => "Customer", :password => 'customer', :password_confirmation => 'customer')
    @customer_email = @customer.email_addresses.create(:address => "customer@walnut.com")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    # make owner a company manager
    @company.grant_role('company manager', @owner)
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
        assert_select "input#email_address", 1
        assert_select "input#email_address.required", 0
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

      context "and a valid staff invitation" do
        setup do
          @sender           = Factory(:user)
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company, :role => 'company staff')
          assert @invitation.valid?
          # stub current user as nobody logged in
          @controller.stubs(:current_user).returns(nil)
          get :new, :invitation_token => @invitation.token, :role => 'company staff'
        end

        should_change("User.count", :by => 1) { User.count } # for the sender user object
        should_change("Invitation.count", :by => 1) { Invitation.count }

        should_not_assign_to :error_message
        should_assign_to(:user)
        should_assign_to(:invitation)
        should_assign_to(:role) {'company staff'}

        should "build user email address" do
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
          get :new, :role => 'company staff'
        end

        should_not_change("User.count") { User.count }

        should_not_assign_to(:error_message)
        should_assign_to(:role) {"company staff"}

        should_respond_with :success
        should_render_template 'users/new.html.haml'
      end

      context "and an invalid invitation" do
        setup do
          get :new, :role => 'company staff', :invitation_token => "0"
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

      context "and a valid staff invitation and valid user properties as an anonymous user" do
        setup do
          @sender           = Factory(:user)
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company, :role => 'company staff')
          assert @invitation.valid?
          # stub current user as nobody
          @controller.stubs(:current_user).returns(nil)
          ActionView::Base.any_instance.stubs(:current_user).returns(nil)
          post :create, {:invitation_token => @invitation.token,
                         :role => 'company staff',
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
        should_assign_to(:role) {"company staff"}

        should "add 'company staff' roles on company to user" do
          @user = User.with_email(@recipient_email).first
          assert_equal ['company staff'], @user.roles_on(@company).collect(&:name).sort
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
          post :create, {:role => 'company staff',
                         :creator => 'user',
                         :user => {:email_addresses_attributes => [{:address => "sanjay@jarna.com"}], :name => "Sanjay Kapoor",
                                   :password => "secret", :password_confirmation => 'secret'}}
        end

        should_change("User.count", :by => 1) { User.count }
        
        should_assign_to(:creator) {"user"}
        should_assign_to :user
        should_assign_to(:role) {"company staff"}
        should_not_assign_to :invitation

        should "have a valid user" do
          assert assigns(:user).valid?
        end

        should "add 'company staff' role on company to user" do
          @user = User.with_email("sanjay@jarna.com").first
          assert_equal ['company staff'], @user.roles_on(@company).collect(&:name).sort
        end

        should "add 'user manager' role on user to user" do
          @user = User.with_email("sanjay@jarna.com").first
          assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
        end

        should_respond_with :redirect
        should_redirect_to('staff index path') { '/staffs' }

        should_set_the_flash_to /Staff user Sanjay Kapoor was successfully created/i
      end
    end
  end
  
  context "create customer" do
    context "as guest user" do
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

      context "for a public company, with no return_to" do
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

        should_redirect_to('root path') { "/" }
        should_set_the_flash_to /Your account was successfully created/i

        should "login as new user" do
          @user = User.with_email("sanjay@walnut.com").first
          assert_equal @user.id, session[:user_id]
        end
      end
      
      context "for a public company, with a return_to" do
        setup do
          # stub current user as nobody
          @controller.stubs(:current_user).returns(nil)
          post :create, {:role => 'company customer',
                         :creator => 'anonymous',
                         :return_to => "/openings",
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

        should_redirect_to('return to path') { "/openings" }
        should_set_the_flash_to /Your account was successfully created/i

        should "login as new user" do
          @user = User.with_email("sanjay@walnut.com").first
          assert_equal @user.id, session[:user_id]
        end
      end
    end
  
    context "as an authenticated user, with an email address" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        post :create, {:role => 'company customer',
                       :creator => 'user',
                       :user => {:email_addresses_attributes => [{:address => "joe@jarna.com"}], :name => "Joe Bloggs",
                                :password => "secret", :password_confirmation => 'secret'}}
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

      should_assign_to(:creator) {"user"}
      should_assign_to(:user)
      should_assign_to(:role) {"company customer"}
      should_not_assign_to :invitation

      should "create user with email" do
        @user = User.with_email("joe@jarna.com").first
        assert_equal @user, assigns(:user)
      end

      should "add 'company customer' role on company to user" do
        @user = User.with_email("joe@jarna.com").first
        assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
      end

      should "add user to company.authorized_customers collection" do
        @user = User.with_email("joe@jarna.com").first
        assert @company.authorized_customers.include?(@user)
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
    
    context "as an authenticated user, without an email address" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        post :create, {:role => 'company customer',
                       :creator => 'user',
                       :user => {:name => "Joe Bloggs", :password => "secret", :password_confirmation => 'secret'}}
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

    context "as an authenticated user, with a phone number" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        post :create, {:role => 'company customer',
                       :creator => 'user',
                       :user => {:phone_numbers_attributes => [{:address => "5559991212", :name => "Mobile"}], :name => "Joe Bloggs",
                                 :password => "secret", :password_confirmation => 'secret'}}
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

      should_assign_to(:creator) {"user"}
      should_assign_to(:user)
      should_assign_to(:role) {"company customer"}
      should_not_assign_to :invitation

      should "create user with phone number" do
        @user = User.with_phone("5559991212").first
        assert_equal @user, assigns(:user)
      end

      should "add 'company customer' role on company to user" do
        @user = User.with_phone("5559991212").first
        assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
      end

      should "add user to company.authorized_customers collection" do
        @user = User.with_phone("5559991212").first
        assert @company.authorized_customers.include?(@user)
      end

      should "add 'user manager' role on user to user" do
        @user = User.with_phone("5559991212").first
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end

      should "not add user as a company provider" do
        assert_equal [], assigns(:user).provided_companies
      end

      should_respond_with :redirect
      should_redirect_to('customers_path') { customers_path }

      should_set_the_flash_to /Customer Joe Bloggs was successfully created/i
    end

    context "with a json request with a duplicate phone number" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        post :create, {:format => "json",
                       :role => 'company customer',
                       :creator => 'user',
                       :user => {:name => "Joe Bloggs", :password => "secret", :password_confirmation => 'secret',
                                 :phone_numbers_attributes => [{:address => "9999999999", :name => "Mobile"}]}
                      }
      end

      should_change("User.count") { User.count }
      should_change("PhoneNumber.count") { PhoneNumber.count}

      should_respond_with_content_type "application/json"

      should "send json response with new user hash" do
        @json = JSON.parse(@response.body)
        @user = User.find_by_name("Joe Bloggs")
        assert_equal Hash["user" => Hash["id" => @user.id, "name" => "Joe Bloggs"]], @json
      end
    end

    context "with a json request with a duplicate email" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        post :create, {:format => "json",
                       :role => 'company customer',
                       :creator => 'user',
                       :user => {:name => "Joe Bloggs", :password => "secret", :password_confirmation => 'secret',
                                 :email_addresses_attributes => [{:address => "owner@walnut.com"}]}
                      }
      end

      should_not_change("User.count") { User.count }
      should_not_change("EmailAddress.count") { EmailAddress.count}

      should_respond_with_content_type "application/json"

      should "send json response with errors user hash" do
        @json = JSON.parse(@response.body)
        assert_equal Hash["user" => Hash["id" => 0, "errors" => ["Address Email address is already in use"]]], @json
      end
    end

    context "with a json request with empty password and confirmation" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        # set flash discard expectation
        ActionController::Flash::FlashHash.any_instance.expects(:discard).once
        post :create, {:format => "json", :role => 'company customer',
                       :creator => 'user',
                       :user => {:name => "Joe Bloggs", :password => '', :password_confirmation => ''}}
      end

      should_change("User.count", :by => 1) { User.count }

      should_respond_with_content_type "application/json"

      should "send json response with new user hash" do
        @json = JSON.parse(@response.body)
        @user = User.find_by_name("Joe Bloggs")
        assert_equal Hash["user" => Hash["id" => @user.id, "name" => "Joe Bloggs"]], @json
      end

      should_set_the_flash_to /Customer Joe Bloggs was successfully created/i
    end

    context "with a json request" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        # set flash discard expectation
        ActionController::Flash::FlashHash.any_instance.expects(:discard).once
        post :create, {:format => "json", :role => 'company customer',
                       :creator => 'user',
                       :user => {:name => "Joe Bloggs", :password => 'secret', :password_confirmation => 'secret'}}
      end

      should_change("User.count", :by => 1) { User.count }

      should_respond_with_content_type "application/json"

      should "send json response with new user hash" do
        @json = JSON.parse(@response.body)
        @user = User.find_by_name("Joe Bloggs")
        assert_equal Hash["user" => Hash["id" => @user.id, "name" => "Joe Bloggs"]], @json
      end

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
        get :edit, :id => @provider.id, :role => 'company staff'
      end

      should_not_assign_to(:index_path)

      should "show 'add existing login' link" do
        assert_select "a#add_rpx", 1
      end

      should "show 'reset password' link" do
        assert_select "a#manager_reset_password", 1
      end

      should_respond_with :success
      should_render_template "users/edit.html.haml"
    end

    context "with 'update users' privilege as manager" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :edit, :id => @provider.id, :role => 'company staff'
      end

      should_assign_to(:index_path) {"/staffs"}

      should "not show 'add existing login' link" do
        assert_select "a#add_rpx", 0
      end

      should "show 'reset password' link" do
        assert_select "a#manager_reset_password", 1
      end

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

    context "with 'update users' privilege as provider" do
      setup do
        @controller.stubs(:current_user).returns(@provider)
        put :update, :id => @provider.id, :user => {:name => "Provider Chg"}, :role => 'company staff'
      end

      should_respond_with :redirect
      should_redirect_to('user edit path') { "/users/#{@provider.id}/edit" }
    end

    context "with 'update users' privilege as owner" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        put :update, :id => @provider.id, :user => {:name => "Provider Chg"}, :role => 'company staff'
      end

      should_respond_with :redirect
      should_redirect_to('staffs index path') { "/staffs" }
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
        @request.env['HTTP_REFERER'] = '/customers'
        @controller.stubs(:current_user).returns(@owner)
        get :edit, :id => @customer.id, :role => 'company customer'
      end

      should_respond_with :success
      should_render_template "users/edit.html.haml"

      should_assign_to(:index_path) { customers_path }
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
      setup do
        @request.env['HTTP_REFERER'] = '/customers'
      end

      context "and change name" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          put :update, :id => @customer.id, :role => 'company customer', 
              :user => {:name => "Customer Chg", :password => '', :password_confirmation => ''}
        end

        should "change name" do
          customer = User.with_email(@customer_email.address).first
          assert_equal "Customer Chg", customer.name
        end

        should "not change password" do
          customer = User.with_email(@customer_email.address).first
          assert User.authenticate(customer.email_address, 'customer')
        end

        should_redirect_to("customers path") { customers_path }
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

        should_redirect_to("customers path") { customers_path }
      end

      context "and change email" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          @email = @customer.primary_email_address
          put :update, :id => @customer.id, :role => 'company customer', 
              :user => {:email_addresses_attributes => {"0" => {:address => "anyone@walnut.com", :id => @email.id}}}
        end
        
        should "change email" do
          @customer.reload
          assert_equal "anyone@walnut.com", @customer.primary_email_address.address
          assert_equal "anyone@walnut.com", @customer.email_address
        end
      end

      context "and add phone number" do
        context "to user in active state" do
          setup do
            assert_equal 'active', @owner.state
            @controller.stubs(:current_user).returns(@owner)
            put :update, :id => @customer.id, :role => 'company customer', 
                :user => {:phone_numbers_attributes => {"1" => {:address => "650-123-9999", :name => "Mobile"}}}
          end

          should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

          should "add user phone number" do
            assert_equal ["6501239999"], @customer.phone_numbers.collect(&:address)
          end
        end

        context "to user in data_missing state" do
          setup do
            @user = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secret", :preferences_phone => 'required')
            @company.grant_role('company customer', @user)
            assert_equal 'data_missing', @user.reload.state
            @controller.stubs(:current_user).returns(@user)
            put :update, :id => @user.id, :role => 'company customer',
                :user => {:phone_numbers_attributes => {"1" => {:address => "650-123-9999", :name => "Mobile"}}}
          end

          should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

          should "add user phone number" do
            assert_equal ["6501239999"], @user.phone_numbers.collect(&:address)
          end

          should "change user state to active" do
            assert_equal 'active', @user.reload.state
          end
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
        # @request.env['HTTP_REFERER'] = 'http://test.com/users'
        @owner.grant_role('admin')
        @controller.stubs(:current_user).returns(@owner)
        get :sudo, :id => @customer.id
      end

      should_assign_to(:sudo_user) { @customer}

      should_redirect_to('openings path') { '/openings' }
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
  
  context "delete user" do
    context "as regular user" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        delete :destroy, :id => @owner.id
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end

    context "who is a company manager" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        delete :destroy, :id => @owner.id
      end

      should_assign_to(:company_roles) { ['company manager', 'company provider', 'company staff'] }

      should "not delete user" do
        assert User.find_by_id(@owner.id)
      end

      should_redirect_to('users path') { "/users" }
    end
    
    context "who is a company provider" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        delete :destroy, :id => @provider.id
      end

      should_assign_to(:company_roles) { ['company provider', 'company staff'] }

      should "not delete user" do
        assert User.find_by_id(@owner.id)
      end

      should_redirect_to('users path') { "/users" }
    end
    
    context "who is a company customer" do
      setup do
        # add customer
        @customer = Factory(:user, :name => "Customer")
        @company.grant_role('company customer', @customer)
        @controller.stubs(:current_user).returns(@owner)
        delete :destroy, :id => @customer.id
      end

      should_assign_to(:company_roles) { ['company customer'] }

      should "delete user" do
        assert_nil User.find_by_id(@customer.id)
      end

      should_redirect_to('users path') { "/users" }
    end
  end
  
  context "grant" do
    context "as regular user" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        put :grant, :id => @owner.id, :role => 'manager'
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end

    context "company provider as manager" do
      setup do
        @request.env['HTTP_REFERER'] = '/staffs'
        @controller.stubs(:current_user).returns(@owner)
        put :grant, :id => @provider.id, :role => 'manager'
      end

      should "add provider as a company manager" do
        assert_equal ['company manager', 'company provider', 'company staff'], @provider.roles_on(@company).collect(&:name).sort
      end

      should_redirect_to('referer') { '/staffs' }
    end

    context "company provider to user" do
      setup do
        @request.env['HTTP_REFERER'] = '/staffs'
        @controller.stubs(:current_user).returns(@owner)
        @user = Factory(:user)
        put :grant, :id => @user.id, :role => 'provider'
      end

      should "add user as a company provider and company staff" do
        assert_equal ['company provider', 'company staff'], @user.roles_on(@company).collect(&:name).sort
      end

      should_redirect_to('referer') { '/staffs' }
    end

    context "company provider to user with company staff role" do
      setup do
        @request.env['HTTP_REFERER'] = '/staffs'
        @controller.stubs(:current_user).returns(@owner)
        @user = Factory(:user)
        @company.grant_role('company staff', @user)
        put :grant, :id => @user.id, :role => 'provider'
      end

      should "add user as a company provider" do
        assert_equal ['company provider', 'company staff'], @user.roles_on(@company).collect(&:name).sort
      end

      should_redirect_to('referer') { '/staffs' }
    end
  end

  context "revoke" do
    context "owner as company manager" do
      context "as owner" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          put :revoke, :id => @owner.id, :role => 'manager'
        end

        should "not remove owner as a company manager" do
          assert_equal ['company manager', 'company provider', 'company staff'], @owner.roles_on(@company).collect(&:name).sort
        end
      end
    end

    context "provider as company manager" do
      setup do
        # make provider a company manager
        @provider.grant_role('company manager', @company)
        assert_equal ['company manager', 'company provider', 'company staff'], @provider.roles_on(@company).collect(&:name).sort
      end
      context "as owner" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          put :revoke, :id => @provider.id, :role => 'manager'
        end

        should "remove provider as a company manager" do
          assert_equal ['company provider', 'company staff'], @provider.roles_on(@company).collect(&:name).sort
        end
      end
    end

    context "provider as company provider" do
      setup do
        @request.env['HTTP_REFERER'] = '/staffs'
        @controller.stubs(:current_user).returns(@provider)
        put :revoke, :id => @provider.id, :role => 'provider'
      end

      should "remove provider as a company provider" do
        assert_equal ['company staff'], @provider.roles_on(@company).collect(&:name)
      end

      should_redirect_to('staffs path') { '/staffs' }
    end
    
    context "owner as company provider" do
      context "as regular user" do
        setup do
          @controller.stubs(:current_user).returns(@user)
          put :revoke, :id => @owner.id, :role => 'provider'
        end

        should_redirect_to('unauthorized_path') { unauthorized_path }
      end

      context "as owner" do
        setup do
          @request.env['HTTP_REFERER'] = '/staffs'
          @controller.stubs(:current_user).returns(@owner)
          put :revoke, :id => @owner.id, :role => 'provider'
        end

        should "remove owner as a company provider" do
          assert_equal ['company manager', 'company staff'], @owner.roles_on(@company).collect(&:name).sort
        end

        should "return false as company.has_provider?" do
          assert_false @company.has_provider?(@owner)
        end

        should "remove owner from authorized_providers collection" do
          assert_false @company.reload.authorized_providers.include?(@owner)
        end

        should "set the flash" do
          assert_match /User Joe Owner has been removed as a company provider/, flash[:notice]
        end

        should_redirect_to('staffs path') { "/staffs" }
      end

      context "as non-provider" do
        setup do
          # remove owner as a company provider
          @company.user_providers.delete(@owner)
          assert_false @company.has_provider?(@owner)
          assert_false @company.reload.authorized_providers.include?(@owner)
          @controller.stubs(:current_user).returns(@owner)
          put :revoke, :id => @owner.id, :role => 'provider'
        end

        should "set the flash" do
          assert_match /User Joe Owner is not a company provider/, flash[:notice]
        end

        should_redirect_to('user edit path') { "/users/#{@owner.id}/edit" }
      end
    end
  end
end
