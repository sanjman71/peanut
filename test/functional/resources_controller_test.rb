require 'test/test_helper'
require 'test/factories'

class ResourcesControllerTest < ActionController::TestCase

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @controller   = ResourcesController.new
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # owner is company manager
    @owner.grant_role('company manager', @company)
    # create provider
    @provider     = Factory(:user, :name => "Provider")
    @company.providers.push(@provider)
    @provider.grant_role('company provider', @provider)
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
  end

  context "create resource" do
    context "without privilege 'create resources'" do
      setup do
        @controller.stubs(:current_user).returns(@provider)
        post :create
      end

      should_redirect_to("unauthorized_path") { unauthorized_path }
    end

    context "with an empty resource name" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        post :create, :resource => {:name => ""}
      end

      should_respond_with :success
      should_render_template 'resources/new.html.haml'
      should_assign_to :resource
      should_not_change("Resource.count") { Resource.count }

      should "have an invalid resource" do
        assert_equal false, assigns(:resource).valid?
      end
    end

    context "with a valid person" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        post :create, :resource => {:name => "Mac Truck"}
      end

      should_assign_to :resource
      should_set_the_flash_to /Created resource/i
      should_change("Resource.count", :by => 1) { Resource.count }

      should_respond_with :redirect
      should_redirect_to('providers_path') { providers_path }
    end
  end

end