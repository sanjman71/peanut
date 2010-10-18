require 'test_helper'

class CalendarControllerTest < ActionController::TestCase

  # list calendars
  should_route :get, '/calendars',  :controller => 'calendar', :action => 'index'
  
  # show provider calendar
  should_route :get, '/users/1/calendar',
               :controller => 'calendar', :action => 'show', :provider_type => 'users', :provider_ids => 1

  # provider calendar events
  should_route :get, '/users/1/calendar/events',
               :controller => 'calendar', :action => 'events', :provider_type => 'users', :provider_ids => 1
  should_route :get, '/users/1/calendar/events/20100101..20100301',
               :controller => 'calendar', :action => 'events', :provider_type => 'users', :provider_ids => 1,
               :start => '20100101', :end => '20100301'
  should_route :get, '/users/1/calendar/events/20100101..20100301.pdf',
               :controller => 'calendar', :action => 'events', :provider_type => 'users', :provider_ids => 1, :format => 'pdf',
               :start => '20100101', :end => '20100301'
  should_route :get, '/users/1/calendar/events/20100101..20100301.email',
               :controller => 'calendar', :action => 'events', :provider_type => 'users', :provider_ids => 1, :format => 'email',
               :start => '20100101', :end => '20100301'

  # search provider calendar
  should_route :post, '/users/1/calendar/search', 
               :controller => 'calendar', :action => 'search', :provider_type => 'users', :provider_ids => 1

  # old calendar routes
  should_route :get, '/users/1/calendar2/when/today.pdf',
               :controller => 'calendar', :action => 'show2', :provider_type => 'users', :provider_id => 1, :when => 'today', :format => 'pdf'

  should_route :get, '/users/1/calendar2/daily/01012009',
               :controller => 'calendar', :action => 'show2', :provider_type => 'users', :provider_id => 1, :range_type => 'daily', :start_date => '01012009'
  should_route :get, '/users/1/calendar2/weekly/01012009',
               :controller => 'calendar', :action => 'show2', :provider_type => 'users', :provider_id => 1, :range_type => 'weekly', :start_date => '01012009'
  should_route :get, '/users/1/calendar2/monthly/01012009',
               :controller => 'calendar', :action => 'show2', :provider_type => 'users', :provider_id => 1, :range_type => 'monthly', :start_date => '01012009'
  
  should_route :get, '/users/1/calendar2/when/today',
               :controller => 'calendar', :action => 'show2', :provider_type => 'users', :provider_id => 1, :when => 'today'

  should_route :get, '/users/1/calendar2/when/next-2-weeks/20100101',
               :controller => 'calendar', :action => 'show2', :provider_type => 'users', :provider_id => 1, :when => 'next-2-weeks', :start_date => "20100101"

  should_route :get, '/users/1/calendar2/range/20100101..20100201',
               :controller => 'calendar', :action => 'show2', :provider_type => 'users', :provider_id => 1, :start_date => "20100101", :end_date => "20100201"

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @owner_email  = @owner.email_addresses.create(:address => 'owner@walnutcalendar.com')
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

  context "index" do
    context "without 'read calendars' privilege" do
      setup do
        get :index
      end

      should_redirect_to("unauthorized_path") { unauthorized_path } 
      should_set_the_flash_to /You are not authorized/
    end

    context "for a company with no providers" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end

      should_redirect_to("company root path") { '/' }
    end

    context "for a company that has 1 provider" do
      setup do
        # add company provider
        @johnny = Factory(:user, :name => "Johnny")
        @company.user_providers.push(@johnny)
        # search as the company manager
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end

      should_redirect_to("johnny's calendar") { "/#{@johnny.tableize}/#{@johnny.id}/calendar" }
    end

    context "from a mobile device" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :index, :mobile => '1'
      end

      should_respond_with :success
      should_render_template 'calendar/index.mobile.haml'
    end
  end

  context "show provider's calendar" do
    context "without 'read calendars' privilege" do
      setup do
        add_mary_and_johnny_as_providers
        @user = Factory(:user, :name => "User")
        # random user wants to see johnny's calendar
        @controller.stubs(:current_user).returns(@user)
        get :show, :provider_type => 'users', :provider_ids => @johnny.id
      end
      
      should "redirect to unauthorized path" do
        assert_redirected_to("/unauthorized")
      end
    end
    
    context "as another provider" do
      setup do
        add_mary_and_johnny_as_providers
        # mary wants to see johnny's calendar
        @controller.stubs(:current_user).returns(@mary)
        get :show, :provider_type => 'users', :provider_ids => @johnny.id
      end
      
      should "set providers, not allow add appointments" do
        assert_equal [@johnny], assigns(:providers)
        assert_equal @johnny, assigns(:provider)
        # should not have hidden add work appointment form
        assert_select "div.dialog.hide#add_work_appointment_dialog", 0
        assert_select "form#add_work_appointment_form", 0
        # should have link to pdf date range
        assert_select "a#pdf_schedule_date_range", 1
        # should have hidden pdf date range dialog
        assert_select "div.dialog#pdf_schedule_date_range_dialog", 1
        assert_template 'calendar/show.html.haml'
      end
    end
    
    context "as calendar owner" do
      setup do
        add_mary_and_johnny_as_providers
        # johnny wants to see johnny's calendar
        @controller.stubs(:current_user).returns(@johnny)
        get :show, :provider_type => 'users', :provider_ids => @johnny.id
      end

      should "set providers, allow add appointments" do
        assert_equal [@johnny], assigns(:providers)
        assert_equal @johnny, assigns(:provider)
        # should have hidden add work appointment form
        assert_select "div.dialog.hide#add_work_appointment_dialog", 1
        assert_select "form#add_work_appointment_form", 1
        # should have link to pdf date range
        assert_select "a#pdf_schedule_date_range", 1
        # should have hidden pdf date range dialog
        assert_select "div.dialog#pdf_schedule_date_range_dialog", 1
        assert_template 'calendar/show.html.haml'
      end
    end
  end

  context "show2 provider calendar as the provider" do
    context "using default when" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@johnny)
        get :show2, :provider_type => 'users', :provider_id => @johnny.id
      end
  
      should_assign_to(:provider) { @johnny }
      should_assign_to(:providers, :class => Array) { [@johnny, @mary] }
      should_assign_to :free_appointments_by_day, :class => Hash
      should_assign_to :capacity_and_work_by_day, :class => Hash
      should_assign_to :canceled_by_day, :class => Hash
      should_assign_to :waitlists_by_day, :class => Hash
      should_assign_to :vacation_by_day, :class => Hash

      should_assign_to :calendar_markings, :class => Hash
      should_assign_to(:when) { "next 2 weeks" }
      should_assign_to(:today)
      should_not_assign_to(:start_date)
      should_assign_to :daterange, :class => DateRange
      should_assign_to(:calendar_highlight_date) { 'first-activity' }

      should "show date range name" do
        assert_select "h4.calendar.date_range_name", {:count => 1, :text => assigns(:daterange).name(:with_dates => true)}
      end
  
      should "have calendar add menu link" do
        assert_select "a#calendar_add_menu"
      end

      should "have calendar add work appointment link" do
        assert_select "a#calendar_add_work_appointment"
      end

      should "have calendar add free appointment link" do
        assert_select "a#calendar_add_free_appointment"
      end

      should "have hidden add work appointment form" do
        assert_select "div.dialog.hide#add_work_appointment_dialog", 1
        assert_select "form#add_work_appointment_form", 1
      end

      should "have hidden add free appointment form" do
        assert_select "div.dialog.hide#add_free_appointment_dialog", 1
        assert_select "form#add_free_appointment_form", 1
      end

      should "have hidden cancel appointment form" do
        assert_select "div.dialog.hide#cancel_appointment_dialog", 1
        assert_select "form#cancel_appointment_form", 1
      end

      should "have link to pdf today" do
        assert_select "a#pdf_schedule_today[href='/users/%s/calendar2/when/today.pdf']" % @johnny.id, 1
      end

      # should "have link to pdf date range" do
      #   assert_select "a#pdf_schedule_date_range", 1
      # end

      # should "have hidden pdf date range dialog" do
      #   assert_select "div.dialog#pdf_schedule_date_range_dialog", 1
      # end

      should_respond_with :success
      should_render_template 'calendar/show_orig.html.haml'
    end
    
    context "monthly, starting on a specific date" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@johnny)
        get :show2, :provider_type => 'users', :provider_id => @johnny.id, :range_type => 'monthly', :start_date => '20090101'
      end
  
      should_assign_to(:provider) { @johnny }
      should_assign_to(:providers, :class => Array) { [@johnny, @mary] }
      should_assign_to :free_appointments_by_day, :class => Hash
      should_assign_to :capacity_and_work_by_day, :class => Hash
      should_assign_to :canceled_by_day, :class => Hash
      should_assign_to :waitlists_by_day, :class => Hash
      should_assign_to :vacation_by_day, :class => Hash

      should_assign_to :calendar_markings, :class => Hash
      should_assign_to(:today)
      should_not_assign_to(:when)
      should_assign_to(:start_date) { "20090101" }
      should_assign_to :daterange, :class => DateRange
      should_assign_to(:calendar_highlight_date) { 'first-activity' }

      should "show date range name and 'today' link" do
        date_range_name = assigns(:daterange).name(:with_dates => true)
        assert_select "h4.calendar.date_range_name", {:count => 1, :text => /^#{date_range_name}(\s)+Today$/}
      end

      should "have hidden add work appointment form" do
        assert_select "div.dialog.hide#add_work_appointment_dialog", 1
        assert_select "form#add_work_appointment_form", 1
      end

      should "have hidden add free appointment form" do
        assert_select "div.dialog.hide#add_free_appointment_dialog", 1
        assert_select "form#add_free_appointment_form", 1
      end

      should "have hidden cancel appointment form" do
        assert_select "div.dialog.hide#cancel_appointment_dialog", 1
        assert_select "form#cancel_appointment_form", 1
      end

      should "have link to pdf today" do
        assert_select "a#pdf_schedule_today[href='/users/%s/calendar2/when/today.pdf']" % @johnny.id, 1
      end

      # should "have link to pdf date range" do
      #   assert_select "a#pdf_schedule_date_range", 1
      # end

      # should "have hidden pdf date range dialog" do
      #   assert_select "div.dialog#pdf_schedule_date_range_dialog", 1
      # end

      should_respond_with :success
      should_render_template 'calendar/show_orig.html.haml'
    end
  end
  
  context "show2 provider calendar as another provider" do
    setup do
      add_mary_and_johnny_as_providers
      @controller.stubs(:current_user).returns(@mary)
      get :show2, :provider_type => 'users', :provider_id => @johnny.id
    end
  
    should_assign_to(:provider) { @johnny }
    should_assign_to(:providers, :class => Array) { [@johnny, @mary] }
    should_assign_to :free_appointments_by_day, :class => Hash
    should_assign_to :capacity_and_work_by_day, :class => Hash
    should_assign_to :canceled_by_day, :class => Hash
    should_assign_to :waitlists_by_day, :class => Hash
    should_assign_to :vacation_by_day, :class => Hash

    should_assign_to :calendar_markings, :class => Hash
    should_assign_to(:today)
    should_assign_to(:when) { "next 2 weeks" }
    should_assign_to :daterange, :class => DateRange

    should "show date range name" do
      assert_select "h4.calendar.date_range_name", {:count => 1, :text => assigns(:daterange).name(:with_dates => true)}
    end

    should "not have calendar add menu link" do
      assert_select "a#calendar_add_menu", 0
    end

    should "not have calendar add work appointment link" do
      assert_select "a#calendar_add_work_appointment", 0
    end

    should "not have calendar add free appointment link" do
      assert_select "a#calendar_add_free_appointment", 0
    end

    should "not show add appointment form" do
      assert_select "form#add_appointment_form", 0
    end

    should_respond_with :success
    should_render_template 'calendar/show_orig.html.haml'
  end

  context "send calendar as pdf email" do
    context "to provider" do
      setup do
        add_mary_and_johnny_as_providers
        @johnny_email = @johnny.email_addresses.create(:address => 'johnny@walnutcalendar.com')
        @controller.stubs(:current_user).returns(@owner)
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        get :events, :provider_type => 'users', :provider_ids => @johnny.id, :start => '20100101', :end => '20100101', :format => 'email'
      end

      should "set link, subject, email, job" do
        assert_equal "http://www.walnutcalendar.com/users/#{@johnny.id}/calendar/events/20100101..20100101.pdf?token=#{AUTH_TOKEN_INSTANCE}",
                      assigns(:link)
        assert_equal "Your PDF Schedule", assigns(:subject)
        assert_equal @johnny_email, assigns(:email)
        assert assigns(:job)
        assert_redirected_to("/users/#{@johnny.id}/calendar")
      end

      should_change("delayed job count", :by => 1) { Delayed::Job.count }
      # should_redirect_to("calendar show page") { "/users/#{@johnny.id}/calendar" }
    end

    context "to provider without an email" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@owner)
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        get :events, :provider_type => 'users', :provider_ids => @johnny.id, :start => '20100101', :end => '20100101', :format => 'email'
      end

      should "set link, subject; not set email, job" do
        assert_equal "http://www.walnutcalendar.com/users/#{@johnny.id}/calendar/events/20100101..20100101.pdf?token=#{AUTH_TOKEN_INSTANCE}",
                      assigns(:link)
        assert_equal "Your PDF Schedule", assigns(:subject)
        assert_nil assigns(:email)
        assert_nil assigns(:job)
        assert_redirected_to("/users/#{@johnny.id}/calendar")
      end

      should_not_change("delayed job count") { Delayed::Job.count }
    end

    context "to owner email id" do
      setup do
        add_mary_and_johnny_as_providers
        @johnny_email = @johnny.email_addresses.create(:address => 'johnny@walnutcalendar.com')
        @controller.stubs(:current_user).returns(@owner)
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        get :events, :provider_type => 'users', :provider_ids => @johnny.id, :start => '20100101', :end => '20100101', :address => @owner_email.id, :format => 'email'
      end

      should "set link, subject, email, job" do
        assert_equal "http://www.walnutcalendar.com/users/#{@johnny.id}/calendar/events/20100101..20100101.pdf?token=#{AUTH_TOKEN_INSTANCE}",
                      assigns(:link)
        assert_equal "Your PDF Schedule", assigns(:subject)
        assert_equal @owner_email, assigns(:email)
        assert assigns(:job)
        assert_redirected_to("/users/#{@johnny.id}/calendar")
      end

      should_change("delayed job count", :by => 1) { Delayed::Job.count }
    end

    context "to owner email" do
      setup do
        add_mary_and_johnny_as_providers
        @johnny_email = @johnny.email_addresses.create(:address => 'johnny@walnutcalendar.com')
        @controller.stubs(:current_user).returns(@owner)
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        get :events, :provider_type => 'users', :provider_ids => @johnny.id, :start => '20100101', :end => '20100101', :address => @owner_email.address, :format => 'email'
      end

      should "set link, subject, email, job" do
        assert_equal "http://www.walnutcalendar.com/users/#{@johnny.id}/calendar/events/20100101..20100101.pdf?token=#{AUTH_TOKEN_INSTANCE}",
                      assigns(:link)
        assert_equal "Your PDF Schedule", assigns(:subject)
        assert_equal @owner_email, assigns(:email)
        assert assigns(:job)
        assert_redirected_to("/users/#{@johnny.id}/calendar")
      end

      should_change("delayed job count", :by => 1) { Delayed::Job.count }
    end
  end
end
