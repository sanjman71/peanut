require 'test/test_helper'
require 'test/factories'

class ProvidersControllerTest < ActionController::TestCase

  # generic users controller routes
  should_route :get,  '/providers/new', :controller => 'users', :action => 'new', :role => 'provider'
  should_route :post, '/providers/create', :controller => 'users', :action => 'create', :role => 'provider'
  should_route :get,  '/providers/1/edit', :controller => 'users', :action => 'edit', :id => '1', :role => 'provider'
  should_route :put,  '/providers/1', :controller => 'users', :action => 'update', :id => '1', :role => 'provider'

  # providers controller routes
  should_route :get,  '/providers/1', :controller => 'providers', :action => 'show', :id => '1'
  
  def setup
    @controller   = ProvidersController.new
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # make owner the company manager
    @owner.grant_role('manager', @company)
    # add provider
    @company.providers.push(@owner)
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
    should_redirect_to('unauthorized_path') { unauthorized_path }
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
    should_render_template 'providers/index.html.haml'
    should_assign_to(:providers, :class => Array)
  
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
      # add a company provider
      @provider = Factory(:user)
      @company.providers.push(@provider)
      get :index
    end
  
    should_respond_with :success
    should_render_template 'providers/index.html.haml'
    should_assign_to(:providers, :class => Array)
    
    should "be able to change manager role for 1 provider" do
      assert_select "input.checkbox.manager", 1
    end
  end
  
end