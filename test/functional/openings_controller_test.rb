require 'test/test_helper'
require 'test/factories'

class OpeningsControllerTest < ActionController::TestCase

  # search appointments for a specified schedulable, duration and service, with a when range
  should_route :post, 'users/1/services/3/45/openings/this-week/anytime',
               :controller => 'openings', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 3, 
               :duration => 45, :when => 'this-week', :time => 'anytime'

  # search appointments for a specified schedulable, duration and service, with a date range
  should_route :post, 'users/1/services/3/45/openings/20090101..20090201/anytime',
               :controller => 'openings', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 3, 
               :duration => 45, :start_date => '20090101', :end_date => '20090201', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration, with a when range
  should_route :post, 'services/3/120/openings/this-week/anytime', 
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120, :when => 'this-week', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration, with a date range
  should_route :post, 'services/3/120/openings/20090101..20090201/anytime', 
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120, 
               :start_date => '20090101', :end_date => '20090201', :time => 'anytime'
  

  def setup
    @controller   = OpeningsController.new
    # create a valid company, with 1 schedulable and 1 work service
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @johnny       = Factory(:user, :name => "Johnny", :companies => [@company])
    @haircut      = Factory(:work_service, :name => "Haircut", :companies => [@company], :users => [@johnny], :price => 10.00, :duration => 30)
    @company.reload
    # stub current company method for the controller and the view
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
    # stub current localation to be anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    @controller.stubs(:current_locations).returns([])
    
    # stub helper method (not sure why this generates an error?)
    ActionView::Base.any_instance.stubs(:service_duration_select_options).returns([])
  end
  
  context "search company openings with no service specified" do
    setup do
      get :index
    end

    should_respond_with :success
    should_not_assign_to :daterange
    should_assign_to :duration, :equals => '0'
    
    should "have 'nothing' service" do
      assert assigns(:service).nothing?
    end
  end

  context "search company openings with an invalid service" do
    setup do
      get :index, :service_id => 157
    end

    should_respond_with :redirect
    should_redirect_to "openings_path"
  end

  context "search company openings with a valid service, but invalid duration" do
    setup do
      # create company service that does not allow a custom duration
      get :index, :service_id => @haircut.id, :duration => 90, :when => 'this-week', :time => 'anytime'
    end

    should_respond_with :redirect
    should "redirect to openings services path with default duration value" do
      assert_redirected_to("http://www.test.host/services/#{@haircut.id}/30/openings/this-week/anytime")
    end
  end
end
