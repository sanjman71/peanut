require 'test/test_helper'
require 'test/factories'

class ProvidersControllerTest < ActionController::TestCase

  # generic users controller routes
  should_route :get,  '/providers/new', :controller => 'users', :action => 'new', :role => 'company provider'
  should_route :post, '/providers/create', :controller => 'users', :action => 'create', :role => 'company provider'
  should_route :get,  '/providers/1/edit', :controller => 'users', :action => 'edit', :id => '1', :role => 'company provider'
  should_route :put,  '/providers/1', :controller => 'users', :action => 'update', :id => '1', :role => 'company provider'

  # providers controller routes
  should_route :get,  '/providers/1', :controller => 'providers', :action => 'show', :id => '1'
  
  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # owner is the company manager
    @owner.grant_role('company manager', @company)
    @owner.grant_role('user manager', @owner)
    # add user providers
    @provider1    = Factory(:user, :name => "User Provider 1")
    @company.user_providers.push(@provider1)
    @provider1.grant_role('company provider', @company)
    @provider1.grant_role('user manager', @provider1)
    @provider2    = Factory(:user, :name => "User Provider 2")
    @company.user_providers.push(@provider2)
    @provider2.grant_role('company provider', @company)
    @provider2.grant_role('user manager', @provider2)
    # add resource providers
    @resource1    = Factory(:resource, :name => "Resource Provider 1")
    @company.resource_providers.push(@resource1)
    # create user
    @user         = Factory(:user, :name => "User")
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
  end

  context "list users" do
    context "without 'read users' privilege" do
      setup do
        # list users as regular user
        @controller.stubs(:current_user).returns(@user)
        get :index
      end

      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
      should_set_the_flash_to /You are not authorized/
    end

    context "with 'read users' privilege" do
      setup do
        # list users as company provider
        @controller.stubs(:current_user).returns(@provider1)
        get :index
      end

      should_assign_to(:providers, :class => Array) { [@resource1, @provider1, @provider2] }

      should "not be able to change manager role on providers" do
        assert_select "input.checkbox.manager", 0
      end

      should "be able to edit themself" do
        assert_select "a.admin.edit.user", 1
      end

      should "not be able to sudo" do
        assert_select "a.admin.sudo.user", 0
      end

      should_respond_with :success
      should_render_template 'providers/index.html.haml'
    end

    context "with 'update users' privilege" do
      setup do
        # list users as company manager
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end

      should_assign_to(:providers, :class => Array) { [@resource1, @provider1, @provider2] }

      should "be able to change manager role on user providers" do
        assert_select "input.checkbox.manager", 2
      end

      should "be able to edit user and resource providers" do
        assert_select "a.admin.edit.user", 3
      end

      should "not be able to sudo" do
        assert_select "a.admin.sudo.user", 0
      end

      should_respond_with :success
      should_render_template 'providers/index.html.haml'
    end
    
    context "with 'manage site' privilege" do
      setup do
        # list users as admin
        @owner.grant_role('admin')
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end

      should_assign_to(:providers, :class => Array) { [@resource1, @provider1, @provider2] }

      should "be able to change manager role on user providers" do
        assert_select "input.checkbox.manager", 2
      end

      should "be able to edit user and resource providers" do
        assert_select "a.admin.edit.user", 3
      end

      should "be able to sudo to each user" do
        assert_select "a.admin.sudo.user", 3
      end

      should_respond_with :success
      should_render_template 'providers/index.html.haml'
    end
  end
  
end