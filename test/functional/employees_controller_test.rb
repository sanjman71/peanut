require 'test/test_helper'
require 'test/factories'

class EmployeesControllerTest < ActionController::TestCase

  # generic users controller routes
  should_route :get,  '/employees/new', :controller => 'users', :action => 'new', :type => 'employee'
  should_route :post, '/employees/create', :controller => 'users', :action => 'create', :type => 'employee'
  should_route :get,  '/employees/1/edit', :controller => 'users', :action => 'edit', :id => '1', :type => 'employee'
  should_route :put,  '/employees/1', :controller => 'users', :action => 'update', :id => '1', :type => 'employee'

  # employees controller routes
  should_route :get,  '/employees/1', :controller => 'employees', :action => 'show', :id => '1'
  
  def setup
    @controller   = EmployeesController.new
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # make owner the company manager
    @owner.grant_role('company manager', @company)
    @owner.grant_role('company employee', @company)
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
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
      get :index
    end
  
    should_respond_with :success
    should_render_template 'employees/index.html.haml'
    should_assign_to :users, :class => Array
  
    should "not be able to change manager role" do
      assert_select "input.checkbox.manager", 0
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
    should_render_template 'employees/index.html.haml'
    should_assign_to :users, :class => Array
    
    should "be able to change manager role for 1 employee" do
      assert_select "input.checkbox.manager", 1
    end
  end
  
end