require 'test/test_helper'

class StaffsControllerTest < ActionController::TestCase

  # generic users controller routes
  should_route :get,  '/staffs/new', :controller => 'users', :action => 'new', :role => 'company staff'
  should_route :post, '/staffs/create', :controller => 'users', :action => 'create', :role => 'company staff'
  should_route :get,  '/staffs/1/edit', :controller => 'users', :action => 'edit', :id => '1', :role => 'company staff'
  should_route :put,  '/staffs/1', :controller => 'users', :action => 'update', :id => '1', :role => 'company staff'

  # staffs controller routes
  should_route :get,  '/staffs', :controller => 'staffs', :action => 'index'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # owner is a company manager
    @company.grant_role('company manager', @owner)
    # add user providers
    @provider1    = Factory(:user, :name => "User Provider 1")
    @company.user_providers.push(@provider1)
    @provider2    = Factory(:user, :name => "User Provider 2")
    @company.user_providers.push(@provider2)
    # add resource providers
    # @resource1    = Factory(:resource, :name => "Resource Provider 1")
    # @company.resource_providers.push(@resource1)
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

      should_assign_to(:staff, :class => Array) { [@owner, @provider1, @provider2] }
      # should_assign_to(:resources, :class => Array) { [@resource1] }

      should "show staff roles for all staff providers" do
        assert_select "span.show_role", 3
      end

      should "be able to edit themself" do
        assert_select "a.admin.edit.user", 1
      end

      should "not be able to sudo" do
        assert_select "a.admin.sudo.user", 0
      end

      should_respond_with :success
      should_render_template 'staffs/index.html.haml'
    end

    context "with 'update users' privilege" do
      setup do
        # list users as company manager
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end

      should_assign_to(:staff, :class => Array) { [@owner, @provider1, @provider2] }
      # should_assign_to(:resources, :class => Array) { [@resource1] }

      should "show roles on staff manager" do
        assert_select "span.show_role", 1
      end

      should "have links to remove company provider roles on staff providers" do
        assert_select "span.edit_role", 2
      end
      
      should "be able to edit user and resource providers and manager" do
        assert_select "a.admin.edit.user", 3
      end

      should "not be able to sudo" do
        assert_select "a.admin.sudo.user", 0
      end

      should_respond_with :success
      should_render_template 'staffs/index.html.haml'
    end
    
    context "with 'manage site' privilege" do
      setup do
        # list users as admin
        @owner.grant_role('admin')
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end

      should_assign_to(:staff, :class => Array) { [@owner, @provider1, @provider2] }
      # should_assign_to(:resources, :class => Array) { [@resource1] }

      should "have 'no email address' messages on each user provider and manager" do
        assert_select "h4.staff.email span.field_missing", 3
      end

      should "show roles on staff manager" do
        assert_select "span.show_role", 1
      end

      should "have links to remove company provider roles on staff providers" do
        assert_select "span.edit_role", 2
      end

      should "be able to edit user providers and manager" do
        assert_select "a.admin.edit.user", 3
      end

      should "be able to sudo to each user provider and manager but not self" do
        assert_select "a.admin.sudo.user", 2
      end

      should_respond_with :success
      should_render_template 'staffs/index.html.haml'
    end
  end
  
end