require 'test/test_helper'
require 'test/factories'

class ServicesControllerTest < ActionController::TestCase

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create owner and company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # owner is a 'company manager'
    @owner.grant_role('company manager', @company)
    # create provider
    @provider     = Factory(:user, :name => "Provider")
    @provider.grant_role('company provider', @company)
    # create service(s)
    @haircut      = Factory.build(:work_service, :duration => 30.minutes, :name => "Haircut", :price => 1.00)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@provider)
    # create user
    @user         = Factory(:user, :name => "User")
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
  end

  context "new service" do
    context "as guest" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        get :new
      end

      should_redirect_to("unauthorized_path") { unauthorized_path }
    end

    context "as provider" do
      setup do
        @controller.stubs(:current_user).returns(@provider)
        get :new
      end

      should_redirect_to("unauthorized_path") { unauthorized_path }
    end

    context "as owner" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :new
      end

      should_assign_to(:service)

      should_respond_with :success
      should_render_template 'services/new.html.haml'
    end
  end

  context "create service" do
    context "without privilege 'create services'" do
      setup do
        @controller.stubs(:current_user).returns(@provider)
        post :create, :service => {:name => "Massage", :mark_as => 'work', :price => 1000, :duration => 60 * 60}
      end
      
      should_redirect_to("unauthorized_path") { unauthorized_path }
    end
    
    context "with privilege 'create services'" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        post :create, :service => {:name => "Massage", :mark_as => 'work', :price => 1000, :duration => 60 * 60}
      end
      
      should_assign_to :service, :redirect_path
      should_change("Service.count", :by => 1) { Service.count }
      
      should_respond_with :redirect
      should_redirect_to('edit service path') { edit_service_path(assigns(:service)) }
    end
  end
  
  context "list services" do
    context "without privilege 'read services'" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        get :index
      end
      
      should_redirect_to("unauthorized_path") { unauthorized_path }
    end
    
    context "as provider" do
      setup do
        @controller.stubs(:current_user).returns(@provider)
        get :index
      end
  
      should_respond_with :success
      should_render_template 'services/index.html.haml'

      should "show service" do
        assert_select "div.service", 1
      end
      
      should "show service name" do
        assert_select "div.name", 1
      end

      should "show service duration" do
        assert_select "div.duration", 1
      end

      should "not show service price" do
        assert_select "div.price", 0
      end

      should "show service capacity" do
        assert_select "div.capacity", 1
      end

      should "not show add service link" do
        assert_select "a.service.add", 0
      end
    end

    context "as owner" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end
  
      should_respond_with :success
      should_render_template 'services/index.html.haml'

      should "show service" do
        assert_select "div.service", 1
      end

      should "show service name" do
        assert_select "div.name", 1
      end

      should "show service duration" do
        assert_select "div.duration", 1
      end

      should "not show service price" do
        assert_select "div.price", 0
      end

      should "show service capacity" do
        assert_select "div.capacity", 1
      end

      should "show add service link" do
        assert_select "a.service.add", 1
      end
    end
  end
  
end