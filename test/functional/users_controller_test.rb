require 'test/test_helper'
require 'test/factories'

class UsersControllerTest < ActionController::TestCase

  def setup
    @controller   = UsersController.new
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # make owner the company manager
    @owner.grant_role('company manager', @company)
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
  end
  
  context "new employee" do
    context "without 'create users' privilege" do
      setup do
        @controller.stubs(:current_privileges).returns([])
      end
      
      context "and with no invitation" do
        setup do
          get :new, :type => 'employee'
        end

        should_respond_with :redirect
        should_redirect_to 'unauthorized_path'
      end
      
      context "and with an invalid invitation" do
        setup do
          get :new, :type => 'employee', :invitation_token => "0"
        end

        should_respond_with :redirect
        should_redirect_to 'unauthorized_path'
      end

      context "and with a valid invitation" do
        setup do
          @sender           = Factory(:user)
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company)
          assert_valid @invitation
          # stub current user as nobody logged in
          @controller.stubs(:current_user).returns(nil)
          ActionView::Base.any_instance.stubs(:current_user).returns(nil)
          get :new, :invitation_token => @invitation.token, :type => 'employee'
        end
        
        should_respond_with :success
        should_render_template 'users/new.html.haml'
        should_change "User.count", :by => 1 # for the sender user object
        should_change "Invitation.count", :by => 1
        should_not_assign_to :error_message
        should_assign_to :user
        should_assign_to :invitation
        should_assign_to :type, :equals => '"employee"'
        
        should "build new user, but should not create the new user" do
          assert_equal @recipient_email, assigns(:user).email
        end
      end
    end
    
    context "with 'create users' privilege" do
      setup do
        @controller.stubs(:current_privileges).returns(['create users'])
      end
      
      context "and with no invitation" do
        setup do
          # stub current user as nobody logged in
          @controller.stubs(:current_user).returns(nil)
          ActionView::Base.any_instance.stubs(:current_user).returns(nil)
          get :new, :type => 'employee'
        end

        should_respond_with :success
        should_render_template 'users/new.html.haml'
        should_not_change "User.count"
        should_not_assign_to :error_message
        should_assign_to :type, :equals => '"employee"'
      end
      
      context "and with an invalid invitation" do
        setup do
          get :new, :type => 'employee', :invitation_token => "0"
        end

        should_respond_with :redirect
        should_redirect_to 'unauthorized_path'
      end
    end
  end
  
  context "create employee" do
    context "without 'create users' privilege" do
      setup do
        @controller.stubs(:current_privileges).returns([])
      end
      
      context "and with no invitation" do
        setup do
          post :create, {:type => 'employee'}
        end

        should_respond_with :redirect
        should_redirect_to 'unauthorized_path'
      end
      
      context "and with an invalid invitation" do
        setup do
          post :create, {:type => 'employee', :invitation_token => "0"}
        end

        should_respond_with :redirect
        should_redirect_to 'unauthorized_path'
      end
      
      context "and with a valid invitation and valid user properties" do
        setup do
          @sender           = Factory(:user, :email => "sender@peanut.com")
          @recipient_email  = Factory.next(:user_email)
          @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company)
          assert_valid @invitation
          post :create, {:invitation_token => @invitation.token, :type => 'employee',
                         :user => {:email => @recipient_email, :name => "Invited User", :password => 'secret', :password_confirmation => 'secret'}}
          @invitation.reload
        end

        # +1 for the sender user and +1 for the new user
        should_change "User.count", :by => 2
        
        should_assign_to :invitation, :equals => '@invitation'
        should_assign_to :user
        should_assign_to :type, :equals => '"employee"'

        should "have a valid user" do
          assert assigns(:user).valid?
        end

        should "have user as a company employee and as a company schedulable" do
          assert_equal ['company employee'], assigns(:user).roles.collect(&:name).sort
          assert_equal [@company], assigns(:user).companies
        end

        should "have updated invitation's recipient to the new user" do
          assert_equal assigns(:user), @invitation.recipient
        end

        should "have user with the invitation" do
          assert_equal @invitation, assigns(:user).invitation
        end

        should_respond_with :redirect
        should_redirect_to 'login_path'
      end
    end
  
    context "with 'create users' privilege" do
      setup do
        @controller.stubs(:current_privileges).returns(['create users'])
      end
      
      context "and with valid user properties and no invitation, as an anonymous user" do
        setup do
          # stub current user as nobody logged in
          @controller.stubs(:current_user).returns(nil)
          ActionView::Base.any_instance.stubs(:current_user).returns(nil)
          # create user requires a password
          post :create, {:type => 'employee', :creator => 'anonymous',
                         :user => {:email => "sanjay@jarna.com", :name => "Sanjay Kapoor", :password => "secret", :password_confirmation => 'secret'}}
        end
        
        should_change "User.count", :by => 1
        
        should_assign_to :creator, :equals => '"anonymous"'
        should_assign_to :user
        should_assign_to :type, :equals => '"employee"'
        should_not_assign_to :invitation
        
        should "have a valid user" do
          assert assigns(:user).valid?
        end

        should "have user as a company employee and as a company schedulable" do
          assert_equal ['company employee'], assigns(:user).roles.collect(&:name).sort
          assert_equal [@company], assigns(:user).companies
        end

        should "have no invitation" do
          assert_equal nil, assigns(:user).invitation
        end

        should_respond_with :redirect
        should_redirect_to 'login_path'
      end

      context "and with valid user properties and no invitation, as an authenticated user" do
        setup do
          # stub current user as company owner
          @controller.stubs(:current_user).returns(@owner)
          ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
          # create user should automatically generate a password
          post :create, {:type => 'employee', :creator => 'user', :user => {:email => "sanjay@jarna.com", :name => "Sanjay Kapoor"}}
        end
        
        should_change "User.count", :by => 1
        
        should_assign_to :creator, :equals => '"user"'
        should_assign_to :user
        should_assign_to :type, :equals => '"employee"'
        should_not_assign_to :invitation

        should "have a valid user" do
          assert assigns(:user).valid?
        end

        should "have user as a company employee and as a company schedulable" do
          assert_equal ['company employee'], assigns(:user).roles.collect(&:name).sort
          assert_equal [@company], assigns(:user).companies
        end

        should "have no invitation" do
          assert_equal nil, assigns(:user).invitation
        end

        should_set_the_flash_to /Employee Sanjay Kapoor was successfully created/i
        
        should_respond_with :redirect
        should_redirect_to 'login_path'
      end
    end
  end
  
  context "create customer" do
    context "as an anonymous user" do
      setup do
        # stub current user as nobody
        @controller.stubs(:current_user).returns(nil)
        ActionView::Base.any_instance.stubs(:current_user).returns(nil)
        post :create, {:type => 'customer', :creator => 'anonymous',
                      :user => {:email => "sanjay@jarna.com", :name => "Sanjay Kapoor", :password => "secret", :password_confirmation => 'secret'}}
      end

      should_change "User.count", :by => 1
      
      should_assign_to :creator, :equals => '"anonymous"'
      should_assign_to :user
      should_assign_to :type, :equals => '"customer"'
      should_not_assign_to :invitation
      
      should "have a valid user" do
        assert assigns(:user).valid?
      end

      should "have not have user as a company employee or as a company schedulable" do
        assert_equal [], assigns(:user).roles.collect(&:name).sort
        assert_equal [], assigns(:user).companies
      end

      should "have no invitation" do
        assert_equal nil, assigns(:user).invitation
      end

      should_set_the_flash_to /Your account was successfully created/i

      should_respond_with :redirect
      should_redirect_to 'login_path'
    end
    
    context "as an authenticated user" do
      setup do
        # stub current user as the company owner
        @controller.stubs(:current_user).returns(@owner)
        ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
        # create user should automatically generate a password
        post :create, {:type => 'customer', :creator => 'user', :user => {:email => "joe@jarna.com", :name => "Joe Bloggs"}}
      end

      should_change "User.count", :by => 1
    
      should_assign_to :creator, :equals => '"user"'
      should_assign_to :user
      should_assign_to :type, :equals => '"customer"'
      should_not_assign_to :invitation
      
      should "have a valid user" do
        assert assigns(:user).valid?
      end

      should "have not have user as a company employee or as a company schedulable" do
        assert_equal [], assigns(:user).roles.collect(&:name).sort
        assert_equal [], assigns(:user).companies
      end

      should "have no invitation" do
        assert_equal nil, assigns(:user).invitation
      end

      should_set_the_flash_to /Customer Joe Bloggs was successfully created/i

      should_respond_with :redirect
      should_redirect_to 'login_path'
    end
  end

  context "list all users without ['read users'] privilege" do
    setup do
      # stub privileges
      @controller.stubs(:current_privileges).returns([])
      # stub current user methods
      @controller.stubs(:current_user).returns(@owner)
      ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
      # stub has_role? method
      @owner.stubs(:has_role?).returns(false)
      get :index
    end
  
    should_respond_with :redirect
    should_redirect_to 'unauthorized_path'
    should_set_the_flash_to /You are not authorized/
  end
  
  context "list all users with ['read users'] privileges" do
    setup do
      # stub privileges
      @controller.stubs(:current_privileges).returns(['read users'])
      # stub current user methods
      @controller.stubs(:current_user).returns(@owner)
      ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
      # ignore owner as company manager
      @owner.stubs(:has_role?).returns(false)
      get :index
    end
  
    should_respond_with :success
    should_render_template 'users/index.html.haml'
    should_assign_to :users, :class => Array
    should_not_assign_to :company_manager
  
    should "not be able to change manager role or toggle user calendar" do
      assert_select "input.checkbox.manager", 0
      assert_select "input.checkbox.calendar", 0
    end
  end

  context "list all users with ['read users', 'update users'] privileges" do
    setup do
      # stub privileges
      @controller.stubs(:current_privileges).returns(['read users', 'update users'])
      # stub current user methods
      @controller.stubs(:current_user).returns(@owner)
      ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
      # add a company employee
      @employee = Factory(:user)
      @employee.grant_role('company employee', @company)
      get :index
    end
  
    should_respond_with :success
    should_render_template 'users/index.html.haml'
    should_assign_to :users, :class => Array
    should_assign_to :company_manager, :equals => 'true'
    
    should "be able to change user calendar for 2 employees" do
      assert_select "input.checkbox.calendar", 2
    end
    
    should "be able to change manager role for 1 employee" do
      assert_select "input.checkbox.manager", 1
    end
  end
end
