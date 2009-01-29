require 'test/test_helper'
require 'test/factories'

class ServicesControllerTest < ActionController::TestCase

  def setup
    @controller = ServicesController.new
    @company    = stub_subdomain
  end

  context "create service" do
    context "without privilege ['create services']" do
      setup do
        @controller.stubs(:has_stubbed_privilege?).with("create services").returns(false)
        xhr :post, :create, :service => {:name => "New service"}
      end
      
      should_redirect_to "unauthorized_path"
    end
    
    context "with privilege ['create services']" do
      setup do
        @controller.stubs(:has_stubbed_privilege?).with("create services").returns(true)
        xhr :post, :create, :service => {:name => "New service"}
      end
      
      should_respond_with :success
      should_render_template 'services/create.js.rjs'
    end
  end
  
  context "list services" do
    context "without privilege ['read services']" do
      setup do
        @controller.stubs(:has_stubbed_privilege?).with("read services").returns(false)
        get :index
      end
      
      should_redirect_to "unauthorized_path"
    end
    
    context "with privilege ['read services'], but not ['create services']" do
      setup do
        @controller.stubs(:has_stubbed_privilege?).with("read services").returns(true)
        @controller.stubs(:has_stubbed_privilege?).with("create services").returns(false)
        get :index
      end

      should_respond_with :success
      
      should "not show add service form" do
        assert_select "form#new_service_form", 0
      end
    end
    
    context "with privilege ['read services', 'create services']" do
      setup do
        @controller.stubs(:has_stubbed_privilege?).with("read services").returns(true)
        @controller.stubs(:has_stubbed_privilege?).with("create services").returns(true)
        get :index
      end

      should_respond_with :success
    
      should "show add service form" do
        assert_select "form#new_service_form", 1
      end
    end
  end
  
end