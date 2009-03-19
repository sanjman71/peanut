require 'test/test_helper'
require 'test/factories'

class ServicesControllerTest < ActionController::TestCase

  def setup
    @controller   = ServicesController.new
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
  end

  context "create service" do
    context "without privilege ['create services']" do
      setup do
        @controller.stubs(:current_privileges).returns([])
        xhr :post, :create, :service => {:name => "New service"}
      end
      
      should_redirect_to "unauthorized_path"
    end
    
    context "with privilege ['create services']" do
      setup do
        @controller.stubs(:current_privileges).returns(["create services"])
        xhr :post, :create, :service => {:name => "New service"}
      end
      
      should_respond_with :success
      should_render_template 'services/create.js.rjs'
    end
  end
  
  context "list services" do
    context "without privilege ['read services']" do
      setup do
        @controller.stubs(:current_privileges).returns([])
        get :index
      end
      
      should_redirect_to "unauthorized_path"
    end
    
    context "with privilege ['read services'], but not ['create services']" do
      setup do
        @controller.stubs(:current_privileges).returns(["read services"])
        get :index
      end
  
      should_respond_with :success
      
      should "not show add service form" do
        assert_select "form#new_service_form", 0
      end
    end
    
    context "with privilege ['read services', 'create services']" do
      setup do
        @controller.stubs(:current_privileges).returns(["read services", "create services"])
        get :index
      end
  
      should_respond_with :success
    
      should "show add service form" do
        assert_select "form#new_service_form", 1
      end
    end
  end
  
end