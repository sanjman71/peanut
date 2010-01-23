require 'test/test_helper'

class CalendarControllerTest < ActionController::TestCase

  # show provider calendar
  should_route :get, '/users/1/calendar',  :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1
  should_route :get, '/users/1/calendar.pdf',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :format => 'pdf'
  should_route :get, '/users/1/calendar/when/today.pdf',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :when => 'today', :format => 'pdf'

  should_route :get, '/users/1/calendar/daily/01012009',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :range_type => 'daily', :start_date => '01012009'
  should_route :get, '/users/1/calendar/weekly/01012009',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :range_type => 'weekly', :start_date => '01012009'
  should_route :get, '/users/1/calendar/monthly/01012009',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :range_type => 'monthly', :start_date => '01012009'
  
  should_route :get, '/users/1/calendar/when/today',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :when => 'today'

  should_route :get, '/users/1/calendar/when/next-2-weeks/20100101',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :when => 'next-2-weeks', :start_date => "20100101"

  should_route :get, '/users/1/calendar/range/20100101..20100201',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_id => 1, :start_date => "20100101", :end_date => "20100201"

  # search provider calendar
  should_route :post, '/users/1/calendar/search', 
               :controller => 'calendar', :action => 'search', :provider_type => 'users', :provider_id => 1
    
  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    # stub current company
    @controller.stubs(:current_company).returns(@company)
    # stub current location to be anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    # set the request hostname
    @request.host = "www.walnutcalendar.com"
  end

  context "search company calendars without 'read calendars' privilege" do
    setup do
      get :index
    end

    should_redirect_to("unauthorized_path") { unauthorized_path } 
    should_set_the_flash_to /You are not authorized/
  end

  context "search company calendars for a company with no providers" do
    setup do
      @controller.stubs(:current_user).returns(@owner)
      get :index
    end

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
  
  context "show provider calendar as the provider" do
    context "using default when" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@johnny)
        get :show, :provider_type => 'users', :provider_id => @johnny.id
      end
  
      should_assign_to(:provider) { @johnny }
      should_assign_to(:providers, :class => Array) { [@johnny, @mary] }
      should_assign_to :stuff_by_day, :class => ActiveSupport::OrderedHash
      should_assign_to :capacity_and_work_by_free_appt, :class => Hash
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to(:when) { "next 2 weeks" }
      should_assign_to(:today)
      should_not_assign_to(:start_date)
      should_assign_to :daterange, :class => DateRange

      should "show date range name" do
        assert_select "h4.calendar.date_range_name", {:count => 1, :text => assigns(:daterange).name(:with_dates => true)}
      end
      
      should "show add appointment form" do
        assert_select "form#add_appointment_form", 1
      end

      should "have hidden send message form" do
        assert_select "div#send_message", 1
      end

      should "have link to pdf today" do
        assert_select "a#pdf_schedule_today[href='/users/%s/calendar/when/today.pdf']" % @johnny.id, 1
      end

      should "have link to pdf date range" do
        assert_select "a#pdf_schedule_date_range", 1
      end

      should "have hidden pdf date range dialog" do
        assert_select "div.dialog#pdf_schedule_date_range_dialog", 1
      end

      should_respond_with :success
      should_render_template 'calendar/show.html.haml'
    end
    
    context "monthly, starting on a specific date" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@johnny)
        get :show, :provider_type => 'users', :provider_id => @johnny.id, :range_type => 'monthly', :start_date => '20090101'
      end
  
      should_assign_to(:provider) { @johnny }
      should_assign_to(:providers, :class => Array) { [@johnny, @mary] }
      should_assign_to :stuff_by_day, :class => ActiveSupport::OrderedHash
      should_assign_to :capacity_and_work_by_free_appt, :class => Hash
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to(:today)
      should_not_assign_to(:when)
      should_assign_to(:start_date) { "20090101" }
      should_assign_to :daterange, :class => DateRange

      should "show date range name and 'today' link" do
        date_range_name = assigns(:daterange).name(:with_dates => true)
        assert_select "h4.calendar.date_range_name", {:count => 1, :text => /^#{date_range_name}(\s)+Today$/}
      end

      should "show add appointment form" do
        assert_select "form#add_appointment_form", 1
      end

      should "have hidden send message form" do
        assert_select "div#send_message", 1
      end
      
      should "have link to pdf today" do
        assert_select "a#pdf_schedule_today[href='/users/%s/calendar/when/today.pdf']" % @johnny.id, 1
      end

      should "have link to pdf date range" do
        assert_select "a#pdf_schedule_date_range", 1
      end

      should "have hidden pdf date range dialog" do
        assert_select "div.dialog#pdf_schedule_date_range_dialog", 1
      end

      should_respond_with :success
      should_render_template 'calendar/show.html.haml'
    end
  end
  
  context "show provider calendar as another provider" do
    setup do
      add_mary_and_johnny_as_providers
      @controller.stubs(:current_user).returns(@mary)
      get :show, :provider_type => 'users', :provider_id => @johnny.id
    end
  
    should_assign_to(:provider) { @johnny }
    should_assign_to(:providers, :class => Array) { [@johnny, @mary] }
    should_assign_to :stuff_by_day, :class => ActiveSupport::OrderedHash
    should_assign_to :capacity_and_work_by_free_appt, :class => Hash
    should_assign_to :calendar_markings, :class => Hash
    should_assign_to(:today)
    should_assign_to(:when) { "next 2 weeks" }
    should_assign_to :daterange, :class => DateRange

    should "show date range name" do
      assert_select "h4.calendar.date_range_name", {:count => 1, :text => assigns(:daterange).name(:with_dates => true)}
    end

    should "not show add appointment form" do
      assert_select "form#add_appointment_form", 0
    end

    should "have hidden send message form" do
      assert_select "div#send_message", 1
    end

    should_respond_with :success
    should_render_template 'calendar/show.html.haml'
  end

end
