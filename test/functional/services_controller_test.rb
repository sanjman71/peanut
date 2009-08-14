require 'test/test_helper'
require 'test/factories'

class ServicesControllerTest < ActionController::TestCase

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @controller   = ServicesController.new
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
    # create user
    @user         = Factory(:user, :name => "User")
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
  end

  context "create service" do
    context "without privilege 'create services'" do
      setup do
        @controller.stubs(:current_user).returns(@provider)
        post :create, :service => {:name => "Massage", :mark_as => 'work', :price => 1000, :duration => 60}
      end
      
      should_redirect_to("unauthorized_path") { unauthorized_path }
    end
    
    context "with privilege 'create services'" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        post :create, :service => {:name => "Massage", :mark_as => 'work', :price => 1000, :duration => 60}
      end
      
      should_assign_to :service, :redirect_path
      should_change("Service.count", :by => 1) { Service.count }
      
      should_respond_with :redirect
      should_redirect_to('edit service path') { edit_service_path(assigns(:service)) }
    end
  end
  
  context "show services" do
    context "without privilege 'read services'" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        get :index
      end
      
      should_redirect_to("unauthorized_path") { unauthorized_path }
    end
    
    context "with privilege 'read services'" do
      setup do
        @controller.stubs(:current_user).returns(@provider)
        get :index
      end
  
      should_respond_with :success
      
      should "not show add service form" do
        assert_select "form#new_service_form", 0
      end
    end
  end
  
end