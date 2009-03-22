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
  
  context "search company calendars as an unauthorized user" do
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

  context "search company calendars for a company that has 1 schedulable" do
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
  
  context "add company schedulables" do
    setup do
      # add johnny as a company employee
      @johnny = Factory(:user, :name => "Johnny", :companies => [@company])
      @johnny.grant_role("company employee", @company)
      # add mary as a company employee
      @mary = Factory(:user, :name => "Johnny", :companies => [@company])
      @mary.grant_role("company employee", @company)
      @company.reload
    end
    
    context "and have johnny view johnny's calendar for this week" do
      setup do
        # stub current user
        @controller.stubs(:current_user).returns(@johnny)
        ActionView::Base.any_instance.stubs(:current_user).returns(@johnny)
        # stub user privileges, johnny should have 'read calendars' privilege as 'company employee'
        @controller.stubs(:current_privileges).returns(["read calendars"])
        # stub calendar markings
        @controller.stubs(:build_calendar_markings).returns(Hash.new)
        get :show, :schedulable_type => 'users', :schedulable_id => @johnny.id
      end

      should_respond_with :success
      should_render_template 'calendar/show.html.haml'
      
      should "show add free time form" do
        assert_select "form#add_free_time_form", 1
      end
      
      should_assign_to :schedulable, :equals => '@johnny'
      should_assign_to :schedulables, :class => Array
      should_assign_to :appointments, :class => Array
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to :when, :equals => '"this week"'
      should_assign_to :daterange, :class => DateRange
    end
    
    context "and have johnny edit johnny's calendar" do
      setup do
        # stub current user
        @controller.stubs(:current_user).returns(@johnny)
        ActionView::Base.any_instance.stubs(:current_user).returns(@johnny)
        # stub user privileges
        @controller.stubs(:current_privileges).returns(["read calendars"])
        # stub calendar markings
        @controller.stubs(:build_calendar_markings).returns(Hash.new)
        get :edit, :schedulable_type => 'users', :schedulable_id => @johnny.id
      end

      should_respond_with :success
      should_render_template 'calendar/edit.html.haml'

      should_assign_to :schedulable, :equals => '@johnny'
      should_assign_to :schedulables, :class => Array
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to :daterange, :class => DateRange
    end
    
    context "and have mary view johnny's calendar for this week" do
      setup do
        # stub current user
        @controller.stubs(:current_user).returns(@mary)
        ActionView::Base.any_instance.stubs(:current_user).returns(@mary)
        # stub user privileges, mary should have 'read calendars' privilege as 'company employee'
        @controller.stubs(:current_privileges).returns(['read calendars'])
        # stub calendar markings
        @controller.stubs(:build_calendar_markings).returns(Hash.new)
        get :show, :schedulable_type => 'users', :schedulable_id => @johnny.id
      end
      
      should_respond_with :success
      should_render_template 'calendar/show.html.haml'

      should "not show add free time form" do
        assert_select "form#add_free_time_form", 0
      end

      should_assign_to :schedulable, :equals => '@johnny'
      should_assign_to :schedulables, :class => Array
      should_assign_to :appointments, :class => Array
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to :when, :equals => '"this week"'
      should_assign_to :daterange, :class => DateRange
    end

    context "and have mary edit johnny's calendar" do
      setup do
        # stub current user
        @controller.stubs(:current_user).returns(@mary)
        ActionView::Base.any_instance.stubs(:current_user).returns(@mary)
        # stub user privileges
        @controller.stubs(:current_privileges).returns(["read calendars"])
        get :edit, :schedulable_type => 'users', :schedulable_id => @johnny.id
      end

      should_respond_with :redirect
      should_redirect_to "unauthorized_path"
      should_set_the_flash_to /You are not authorized/
    end
  end
end