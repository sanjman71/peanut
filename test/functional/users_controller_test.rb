require 'test/test_helper'

class UsersControllerTest < ActionController::TestCase

  # user notify route
  should_route :get,  '/users/1/notify/create', :controller => 'users', :action => 'notify', :id => '1', :type => 'create'

  # Don't have the patience to test all these routes:
  # map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }
  
  should_route :get, '/users/1/notify/reset', :controller => 'users', :action => 'notify', :id => "1", :type => "reset"
  should_route :get, '/providers/new',          :controller => 'users', :action => 'new', :role => 'company provider'
  should_route :post, '/providers/create',      :controller => 'users', :action => 'create', :role => 'company provider'
  should_route :get, '/providers/1/edit',     :controller => 'users', :action => 'edit', :role => 'company provider', :id => "1"
  should_route :put, '/providers/1',          :controller => 'users', :action => 'update', :role => 'company provider', :id => "1"
  should_route :get, '/customers/new',          :controller => 'users', :action => 'new', :role => 'company customer'
  should_route :post, '/customers/create',      :controller => 'users', :action => 'create', :role => 'company customer'
  should_route :get, '/customers/1/edit',     :controller => 'users', :action => 'edit', :role => 'company customer', :id => "1"
  should_route :put, '/customers/1',          :controller => 'users', :action => 'update', :role => 'company customer', :id => "1"
  
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
  
    @controller   = UsersController.new
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @customer     = Factory(:user, :name => "Customer")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # make owner the company manager
    @owner.grant_role('company manager', @company)
    # add provider
    @company.providers.push(@owner)
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
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
        
        should_respond_with :success
        should_render_template 'users/new.html.haml'
        
        should_change("User.count", :by => 1) { User.count } # for the sender user object
        should_change("Invitation.count", :by => 1) { Invitation.count }
        
        should_not_assign_to :error_message
        should_assign_to(:user)
        should_assign_to(:invitation)
        should_assign_to(:role) {'company provider'}
        
        should "build new user, but should not create the new user" do
          assert_equal @recipient_email, assigns(:user).email
        end
      end
    end
    
    context "with 'create users' privilege" do
      context "and no invitation" do
        setup do
          # create user as owner
          @controller.stubs(:current_user).returns(@owner)
          get :new, :role => 'company provider'
        end
  
        should_respond_with :success
        should_render_template 'users/new.html.haml'
        
        should_not_change("User.count") { User.count }
        
        should_not_assign_to(:error_message)
        should_assign_to(:role) {"company provider"}
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
          @sender           = Factory(:user, :email => "sender@peanut.com")
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company, :role => 'company provider')
          assert @invitation.valid?
          # stub current user as nobody
          @controller.stubs(:current_user).returns(nil)
          ActionView::Base.any_instance.stubs(:current_user).returns(nil)
          post :create, {:invitation_token => @invitation.token, :role => 'company provider',
                         :user => {:email => @recipient_email, :name => "Invited User", :password => 'secret', :password_confirmation => 'secret'}}
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
          @user = User.find_by_email(@recipient_email)
          assert @company.has_provider?(@user)
        end
  
        should "add provider role on company to suer" do
          @user = User.find_by_email(@recipient_email)
          assert_equal ['company provider'], @user.roles_on(@company).collect(&:name).sort
        end
  
        should "add 'user manager' role on user to user" do
          @user = User.find_by_email(@recipient_email)
          assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
        end
  
        should "have updated invitation's recipient to the new user" do
          @user = User.find_by_email(@recipient_email)
          assert_equal @user, @invitation.recipient
        end
      end
      
      context "and with a valid customer invitation and valid user properties as an anonymous user" do
        setup do
          @sender           = Factory(:user, :email => "sender@peanut.com")
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company, :role => 'company customer')
          assert @invitation.valid?
          # stub current user as nobody
          @controller.stubs(:current_user).returns(nil)
          ActionView::Base.any_instance.stubs(:current_user).returns(nil)
          post :create, {:invitation_token => @invitation.token, :role => 'company provider',
                         :user => {:email => @recipient_email, :name => "Invited User", :password => 'secret', :password_confirmation => 'secret'}}
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
          @user = User.find_by_email(@recipient_email)
          assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
        end
  
        should "add 'user manager' role on user to user" do
          @user = User.find_by_email(@recipient_email)
          assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
        end
  
        should "have updated invitation's recipient to the new user" do
          assert_equal assigns(:user), @invitation.recipient
        end
      end
    end
  
    context "with 'create users' privilege" do
      setup do
        # @controller.stubs(:current_privileges).returns(['create users'])
      end
      
      # context "and valid user properties and no invitation, as an anonymous user" do
      #   setup do
      #     # stub current user as nobody logged in
      #     @controller.stubs(:current_user).returns(nil)
      #     ActionView::Base.any_instance.stubs(:current_user).returns(nil)
      #     # create user requires a password
      #     post :create, {:role => 'company provider', :creator => 'anonymous',
      #                    :user => {:email => "sanjay@jarna.com", :name => "Sanjay Kapoor", :password => "secret", :password_confirmation => 'secret'}}
      #   end
      #   
      #   should_change("User.count", :by => 1) { User.count }
      #   
      #   should_assign_to(:creator) {"anonymous"}
      #   should_assign_to :user
      #   should_assign_to(:role) {"company provider"}
      #   should_not_assign_to :invitation
      #   
      #   should "have a valid user" do
      #     assert assigns(:user).valid?
      #   end
      # 
      #   should "add user a company provider" do
      #     @user = User.find_by_email("sanjay@jarna.com")
      #     assert @company.has_provider?(@user)
      #   end
      # 
      #   should "add provider role on company to user" do
      #     @user = User.find_by_email("sanjay@jarna.com")
      #     assert_equal ['company provider'], @user.roles_on(@company).collect(&:name).sort
      #   end
      # 
      #   should "add 'user manager' role on user to user" do
      #     @user = User.find_by_email("sanjay@jarna.com")
      #     assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      #   end
      # 
      #   should_respond_with :redirect
      #   should_redirect_to('root path') {"http://test.host/"}
      # end
  
      context "and valid user properties and no invitation, as an authenticated user" do
        setup do
          # stub current user as company owner
          @controller.stubs(:current_user).returns(@owner)
          # create user should generate a password
          post :create, {:role => 'company provider', :creator => 'user', :user => {:email => "sanjay@jarna.com", :name => "Sanjay Kapoor"}}
        end
        
        should_respond_with :redirect
        should_redirect_to('providers_path') { providers_path }
        
        should_set_the_flash_to /Provider Sanjay Kapoor was successfully created/i
        
        should_change("User.count", :by => 1) { User.count }
        
        should_assign_to(:creator) {"user"}
        should_assign_to :user
        should_assign_to(:role) {"company provider"}
        should_not_assign_to :invitation
  
        should "have a valid user" do
          assert assigns(:user).valid?
        end
  
        should "add user as a company provider" do
          @user = User.find_by_email("sanjay@jarna.com")
          assert @company.has_provider?(@user)
        end
  
        should "add 'company provider' role on company to user" do
          @user = User.find_by_email("sanjay@jarna.com")
          assert_equal ['company provider'], @user.roles_on(@company).collect(&:name).sort
        end
  
        should "add 'user manager' role on user to user" do
          @user = User.find_by_email("sanjay@jarna.com")
          assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
        end
      end
    end
  end
  
  context "create customer" do
    context "as an anonymous user" do
      setup do
        # stub current user as nobody
        @controller.stubs(:current_user).returns(nil)
        post :create, {:role => 'company customer', :creator => 'anonymous',
                      :user => {:email => "sanjay@jarna.com", :name => "Sanjay Kapoor", :password => "secret", :password_confirmation => 'secret'}}
      end
  
      should_respond_with :redirect
      should_redirect_to('root path') {"http://test.host/"}
  
      should_set_the_flash_to /Your account was successfully created/i
  
      should_change("User.count", :by => 1) { User.count }
  
      should_assign_to(:creator) {"anonymous"}
      should_assign_to :user
      should_assign_to(:role) {"company customer"}
      should_not_assign_to :invitation
  
      should "add 'company customer' role on company to user" do
        @user = User.find_by_email("sanjay@jarna.com")
        assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
      end
  
      should "add 'user manager' role on user to user" do
        @user = User.find_by_email("sanjay@jarna.com")
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end
  
      should "not add user as a company provider" do
        @user = User.find_by_email("sanjay@jarna.com")
        assert_equal [], @user.companies
      end
    end
  
    context "as an authenticated user" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        # create user should generate a password
        post :create, {:role => 'company customer', :creator => 'user', :user => {:email => "joe@jarna.com", :name => "Joe Bloggs"}}
      end
  
      should_respond_with :redirect
      should_redirect_to('customers_path') { customers_path }
  
      should_set_the_flash_to /Customer Joe Bloggs was successfully created/i
  
      should_change("User.count", :by => 1) { User.count }
  
      should_assign_to(:creator) {"user"}
      should_assign_to :user
      should_assign_to(:role) {"company customer"}
      should_not_assign_to :invitation
      
      should "add 'company customer' role on company to user" do
        @user = User.find_by_email("joe@jarna.com")
        assert_equal ['company customer'], @user.roles_on(@company).collect(&:name).sort
      end
  
      should "add 'user manager' role on user to user" do
        @user = User.find_by_email("joe@jarna.com")
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end
  
      should "not add user as a company provider" do
        assert_equal [], assigns(:user).companies
      end
    end
  end
  
  context "edit provider" do
    context "as nobody" do
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
  
    context "with 'update users' privilege" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :edit, :id => @owner.id, :role => 'company provider'
      end
    
      should_respond_with :success
      should_render_template "users/edit.html.haml"
    
      should_assign_to(:index_path) {"/providers"}
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
    
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "without 'update users' privilege" do
      setup do
        @user = Factory(:user, :name => "User")
        @controller.stubs(:current_user).returns(@user)
        get :edit, :id => @customer.id, :role => 'company customer'
      end
  
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "with 'update users' privilege" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :edit, :id => @customer.id, :role => 'company customer'
      end
    
      should_respond_with :success
      should_render_template "users/edit.html.haml"
    
      should_assign_to(:index_path) {"/customers"}
    end
  end
  
  context "update customer" do
    context "as nobody" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        put :update, :id => @customer.id, :user => {:name => "Customer Chg"}, :role => 'company customer'
      end
    
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "without 'update users' privilege" do
      setup do
        @user = Factory(:user, :name => "User")
        @controller.stubs(:current_user).returns(@user)
        put :update, :id => @customer.id, :user => {:name => "Customer Chg"}, :role => 'company customer'
      end
  
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "with 'update users' privilege" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        put :update, :id => @customer.id, :user => {:name => "Customer Chg"}, :role => 'company customer'
      end
    
      should_respond_with :redirect
      should_redirect_to('/customers') { "/customers" }
    end
  end
end
