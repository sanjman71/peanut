require 'test/test_helper'
require 'test/factories'

class OpeningsControllerTest < ActionController::TestCase

  # basic index and reschedule paths
  should_route :get, '/openings', :controller => 'openings', :action => 'index'
  should_route :get, '/openings/reschedule', :controller => 'openings', :action => 'index', :type => 'reschedule'
  
  # search appointments for a specified provider, duration and service, with a when range
  should_route :post, 'users/1/services/3/2700/openings/this-week/anytime',
               :controller => 'openings', :action => 'index', :provider_type => 'users', :provider_id => 1, :service_id => 3, 
               :duration => 45.minutes, :when => 'this-week', :time => 'anytime'

  # search appointments for a specified provider, duration and service, with a date range
  should_route :post, 'users/1/services/3/2700/openings/20090101..20090201/anytime',
               :controller => 'openings', :action => 'index', :provider_type => 'users', :provider_id => 1, :service_id => 3, 
               :duration => 45.minutes, :start_date => '20090101', :end_date => '20090201', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration, with a when range
  should_route :post, 'services/3/7200/openings/this-week/anytime', 
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120.minutes, :when => 'this-week', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration, with a date range
  should_route :post, 'services/3/7200/openings/20090101..20090201/anytime', 
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120.minutes, 
               :start_date => '20090101', :end_date => '20090201', :time => 'anytime'

  def setup
    @controller   = OpeningsController.new
    # create a valid company, with 1 provider and 1 work service
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @johnny       = Factory(:user, :name => "Johnny")
    @company.user_providers.push(@johnny)
    @haircut      = Factory.build(:work_service, :name => "Haircut", :price => 10.00, :duration => 30.minutes)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    @company.reload
    # stub current company method for the controller and the view
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
    # stub current location to be anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    @controller.stubs(:current_locations).returns([])

    # stub helper method (not sure why this generates an error?)
    ActionView::Base.any_instance.stubs(:service_duration_select_options).returns([])

    # Set the request hostname
    # @request.host = "www.peanut.com"
  end
  
  context "search company openings with no service specified" do
    setup do
      get :index
    end

    should_respond_with :success
    should_render_template 'openings/index.html.haml'
    should_not_assign_to :daterange
    should_assign_to(:duration) { 0 }

    should "have 'nothing' service" do
      assert assigns(:service).nothing?
    end
  end

  context "search company openings with an invalid service" do
    setup do
      get :index, :service_id => 157
    end

    should_respond_with :redirect
    should_redirect_to("openings_path") { openings_path }
  end

  context "search company openings with a valid service, but invalid duration" do
    setup do
      # create company service that does not allow a custom duration
      get :index, :service_id => @haircut.id, :duration => 90.minutes, :when => 'this-week', :time => 'anytime'
    end

    should_respond_with :redirect
    should_redirect_to "openings services path with default duration value" do
      "/services/#{@haircut.id}/1800/openings/this-week/anytime"
    end
  end
end
