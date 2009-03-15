require 'test/test_helper'
require 'test/factories'

class CalendarControllerTest < ActionController::TestCase

  # show calendar for a specific schedulable
  should_route :get, 'users/1/calendar',  :controller => 'calendar', :action => 'show', :schedulable_type => 'users', :schedulable_id => 1
  should_route :get, 'users/1/calendar.pdf',  
               :controller => 'calendar', :action => 'show', :schedulable_type => 'users', :schedulable_id => 1, :format => 'pdf'
  
  # search calendar for a specific schedulable
  should_route :post, 'users/1/calendar/search', 
               :controller => 'calendar', :action => 'search', :schedulable_type => 'users', :schedulable_id => 1

  # edit calendar for a specific schedulable
  should_route :get, 'users/1/calendar/edit', 
               :controller => "calendar", :action => 'edit', :schedulable_type => "users", :schedulable_id => "1"
  
  def setup
    @controller   = CalendarController.new
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
  end
  
  context "search company calendars with an unauthorized user" do
    setup do
      @controller.stubs(:current_privileges).returns([])
      get :index
    end

    should_respond_with :redirect
    should_redirect_to "unauthorized_path"
    should_set_the_flash_to /You are not authorized/
  end

  context "search company calendars for a company with no schedulables" do
    setup do
      @controller.stubs(:current_privileges).returns(["read calendars"])
      get :index
    end

    should_respond_with :redirect
    should "redirect to company root path" do
      assert_redirected_to("http://www.test.host/")
    end
  end

  context "search company calendars for a company that has a schedulable" do
    setup do
      # add company schedulable
      @johnny = Factory(:user, :name => "Johnny", :companies => [@company])
      # stub user privileges
      @controller.stubs(:current_privileges).returns(["read calendars"])
      get :index
    end

    should_respond_with :redirect
    should "redirect to johnny's calendar" do
      assert_redirected_to("http://www.test.host/#{@johnny.tableize}/#{@johnny.id}/calendar")
    end
  end
  
  context "show johnny's calendar for this week" do
    setup do
      # add company schedulable
      @johnny = Factory(:user, :name => "Johnny", :companies => [@company])
      @company.reload
      # stub user privileges
      @controller.stubs(:current_privileges).returns(["read calendars"])
      # stub calendar markings
      @controller.stubs(:build_calendar_markings).returns(Hash.new)
      get :show, :schedulable_type => 'users', :schedulable_id => @johnny.id
    end

    should_respond_with :success
    should_render_template 'calendar/show.html.haml'
    
    should_assign_to :schedulables, :appointments
    should_assign_to :schedulable, :equals => '@johnny'
    should_assign_to :when, :equals => '"this week"'
  end
end
