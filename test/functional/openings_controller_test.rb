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
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # stub current company method for the controller and the view
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
    # stub current localation to be anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    @controller.stubs(:current_locations).returns([])
    
    # stub helper method (not sure why this generates an error?)
    ActionView::Base.any_instance.stubs(:service_duration_select_options).returns([])
  end
  
  context "search company openings" do
    setup do
      @nothing = Service.nothing
      get :index
    end

    should_respond_with :success
    should_not_assign_to :daterange
    should_assign_to :duration, :equals => '0'
    
    should "have 'nothing' service" do
      assert assigns(:service).nothing?
    end
  end
  
end
