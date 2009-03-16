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
    # stub current user methods
    @controller.stubs(:current_user).returns(@owner)
    ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
  end
  
  context "new user" do
    context "with no invitation" do
      setup do
        get :new
      end
    
      should_respond_with :success
      should_not_change "User.count"
      should_assign_to :error
    end
    
    context "with an invitation" do
      setup do
        @sender           = Factory(:user)
        @recipient_email  = Factory.next(:user_email)
        @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company)
        assert_valid @invitation
        get :new, :invitation_token => @invitation.token
      end
  
      should_respond_with :success
      should_change "User.count", :by => 1 # for the sender user object
      should_change "Invitation.count", :by => 1
      should_not_assign_to :error
      should_assign_to :user
      
      should "build new user, but not create the new user" do
        assert_equal @recipient_email, assigns(:user).email
      end
    end
  end
  
  context "create user" do
    context "with an invitation" do
      setup do
        @sender           = Factory(:user, :email => "sender@peanut.com")
        @recipient_email  = Factory.next(:user_email)
        @invitation       = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company)
        assert_valid @invitation
        post :create, {:invitation_token => @invitation.token, 
                       :user => {:email => @recipient_email, :name => "Invited User", :password => 'secret', :password_confirmation => 'secret'}}
      end
      
      should_assign_to :invitation, :equals => '@invitation'
      should_assign_to :user
      
      should "have created new user as a company employee and a company schedulable" do
        assert assigns(:user).valid?
        assert_equal ['company employee'], assigns(:user).roles.collect(&:name).sort
        assert_equal [@company], assigns(:user).companies
      end
    end
  end
  
  context "list all users without ['read users'] privilege" do
    setup do
      @controller.stubs(:current_privileges).returns([])
      get :index
    end
  
    should_respond_with :redirect
    should_redirect_to 'unauthorized_path'
    should_set_the_flash_to /You are not authorized/
  end
  
  context "list all users with ['read users'] privileges" do
    setup do
      @controller.stubs(:current_privileges).returns(['read users'])
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
      # add a company employee
      @employee = Factory(:user)
      @employee.grant_role('company employee', @company)
      @controller.stubs(:current_privileges).returns(['read users', 'update users'])
      get :index
    end
  
    should_respond_with :success
    should_render_template 'users/index.html.haml'
    should_assign_to :users, :class => Array
    should_assign_to :company_manager, :equals => 'true'
    
    should "be able to change user calendar for 2 company users" do
      assert_select "input.checkbox.calendar", 2
    end
    
    should "be able to change manager role 1 company user" do
      assert_select "input.checkbox.manager", 1
    end
  end
end
