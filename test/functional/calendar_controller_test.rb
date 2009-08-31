require 'test/test_helper'

class CalendarControllerTest < ActionController::TestCase

  # show provider calendar
  should_route :get, 'users/1/calendar',  :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1
  should_route :get, 'users/1/calendar.pdf',  
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :format => 'pdf'
  
  # search provider calendar
  should_route :post, 'users/1/calendar/search', 
               :controller => 'calendar', :action => 'search', :provider_type => 'users', :provider_id => 1
  
  # edit provider calendar
  should_route :get, 'users/1/calendar/block/edit', 
               :controller => "calendar", :action => 'edit_block', :provider_type => "users", :provider_id => "1"
  
  should_route :get, 'users/1/calendar/weekly/edit',
               :controller => "calendar", :action => 'edit_weekly', :provider_type => "users", :provider_id => "1"

  
  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @controller   = CalendarController.new
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    # stub current company method for the controller and the view
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
    # stub current location to be anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    # set the request hostname
    @request.host = "www.walnutcalendar.com"
  end

  def add_mary_and_johnny_as_providers
    # add johnny as a company provider
    @johnny = Factory(:user, :name => "Johnny")
    # @johnny.grant_role('user manager', @johnny)
    @company.user_providers.push(@johnny)
    @johnny.reload
    @company.reload
    @mary = Factory(:user, :name => "Mary")
    # @mary.grant_role('user manager', @mary)
    @company.user_providers.push(@mary)
    @mary.reload
    @company.reload
  end

  context "search company calendars without 'read calendars' privilege" do
    setup do
      get :index
    end

    should_respond_with :redirect
    should_redirect_to("unauthorized_path") { unauthorized_path } 
    should_set_the_flash_to /You are not authorized/
  end

  context "search company calendars for a company with no providers" do
    setup do
      @controller.stubs(:current_user).returns(@owner)
      get :index
    end
  
    should_respond_with :redirect
    should_redirect_to("company root path") { '/' }
  end

  context "search company calendars for a company that has 1 provider" do
    setup do
      # add company provider
      @johnny = Factory(:user, :name => "Johnny")
      @company.user_providers.push(@johnny)
      # search as the company manager
      @controller.stubs(:current_user).returns(@owner)
      get :index
    end
  
    should_respond_with :redirect
    should_redirect_to("johnny's calendar") { "/#{@johnny.tableize}/#{@johnny.id}/calendar" }
  end
  
  context "view provider calendar as the provider" do
    setup do
      add_mary_and_johnny_as_providers
      @controller.stubs(:current_user).returns(@johnny)
      # stub calendar markings
      @controller.stubs(:build_calendar_markings).returns(Hash.new)
      get :show, :provider_type => 'users', :provider_id => @johnny.id
    end
  
    should_respond_with :success
    should_render_template 'calendar/show.html.haml'
    
    should "show add single free time form" do
      assert_select "form#add_single_free_time_form", 1
    end
    
    should_assign_to(:provider) { @johnny }
    should_assign_to(:providers, :class => Array) { [@johnny, @mary] }
    should_assign_to :appointments, :class => Array
    should_assign_to :calendar_markings, :class => Hash
    should_assign_to(:when) { "this week" }
    should_assign_to :daterange, :class => DateRange
  end
  
  context "edit provider calendar as the provider" do
    setup do
      add_mary_and_johnny_as_providers
      @controller.stubs(:current_user).returns(@johnny)
      # stub calendar markings
      @controller.stubs(:build_calendar_markings).returns(Hash.new)
      get :edit_block, :provider_type => 'users', :provider_id => @johnny.id
    end
    
    should_respond_with :success
    should_render_template 'calendar/edit_block.html.haml'
  
    should_assign_to(:provider) { @johnny }
    should_assign_to :providers, :class => Array
    should_assign_to :calendar_markings, :class => Hash
    should_assign_to :daterange, :class => DateRange
  end
    
  context "view provider calendar as another provider" do
    setup do
      add_mary_and_johnny_as_providers
      @controller.stubs(:current_user).returns(@mary)
      # stub calendar markings
      @controller.stubs(:build_calendar_markings).returns(Hash.new)
      get :show, :provider_type => 'users', :provider_id => @johnny.id
    end
  
    should_respond_with :success
    should_render_template 'calendar/show.html.haml'
    
    should "not show add single free time form" do
      assert_select "form#add_single_free_time_form", 0
    end
    
    should_assign_to(:provider) { @johnny }
    should_assign_to(:providers, :class => Array) { [@johnny, @mary] }
    should_assign_to :appointments, :class => Array
    should_assign_to :calendar_markings, :class => Hash
    should_assign_to(:when) { "this week" }
    should_assign_to :daterange, :class => DateRange
  end

  context "edit provider calendar as another provider" do
    setup do
      add_mary_and_johnny_as_providers
      @controller.stubs(:current_user).returns(@mary)
      # stub calendar markings
      @controller.stubs(:build_calendar_markings).returns(Hash.new)
      get :edit_block, :provider_type => 'users', :provider_id => @johnny.id
    end
  
    should_respond_with :redirect
    should_redirect_to("unauthorized_path") { unauthorized_path }
    should_set_the_flash_to /You are not authorized/
  end

end
