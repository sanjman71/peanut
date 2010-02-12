require 'test/test_helper'

class AppointmentsControllerTest < ActionController::TestCase

  # schedule a work apppointment for a specific provider, service and duration
  should_route :get, '/schedule/users/3/services/3/3600/20090303T113000',
               :controller => 'appointments', :action => 'new', :provider_type => 'users', :provider_id => 3, :service_id => 3, 
               :duration => 60.minutes, :start_at => '20090303T113000', :mark_as => 'work'
  should_route :post, '/schedule/users/3/services/3/3600/20090303T113000',
               :controller => 'appointments', :action => 'create_work', :provider_type => 'users', :provider_id => 3, :service_id => 3, 
               :duration => 60.minutes, :start_at => '20090303T113000', :mark_as => 'work'
  should_route :post, '/schedule/work',
               :controller => 'appointments', :action => 'create_work', :mark_as => 'work'
  
  # create free time
  should_route  :post, '/users/3/calendar/free',
                :controller => 'appointments', :action => 'create_free', :provider_type => 'users', :provider_id => 3
  
  should_route  :get, '/users/1/calendar/block/new', 
                :controller => "appointments", :action => 'new_block', :provider_type => "users", :provider_id => 1
  should_route  :post, '/users/3/calendar/block', 
                :controller => 'appointments', :action => 'create_block', :provider_type => 'users', :provider_id => 3
  
  should_route  :get, '/users/3/calendar/weekly/new',
                :controller => 'appointments', :action => 'new_weekly', :provider_type => 'users', :provider_id => 3
  should_route  :post, '/users/3/calendar/weekly', 
                :controller => 'appointments', :action => 'create_weekly', :provider_type => 'users', :provider_id => 3
  should_route  :get, 'users/1/calendar/weekly/1/edit',
                :controller => "appointments", :action => 'edit_weekly', :provider_type => "users", :provider_id => 1, :id => 1
  should_route  :post, '/users/3/calendar/1/weekly', 
                :controller => 'appointments', :action => 'update_weekly', :provider_type => 'users', :provider_id => 3, :id => 1
  
  # rest actions
  should_route :get, '/appointments/1', :controller => 'appointments', :action => 'show', :id => 1
  should_route :get, '/appointments/1/edit', :controller => 'appointments', :action => 'edit', :id => 1
  should_route :put, '/appointments/1', :controller => 'appointments', :action => 'update', :id => 1
  
  # change appointment states
  should_route :get, '/appointments/1/approve', :controller => 'appointments', :action => 'approve', :id => 1
  should_route :get, '/appointments/1/complete', :controller => 'appointments', :action => 'complete', :id => 1
  should_route :get, '/appointments/1/noshow', :controller => 'appointments', :action => 'noshow', :id => 1
  should_route :get, '/appointments/1/cancel', :controller => 'appointments', :action => 'cancel', :id => 1
  
  # show work appointments by state
  should_route :get, '/appointments/upcoming', :controller => 'appointments', :action => 'index', :type => 'work', :state => 'upcoming'
  
  # show a customer's work appointments, with an optional state parameter
  should_route :get, '/customers/1/appointments', :controller => 'appointments', :action => 'index', :customer_id => 1, :type => 'work'
  should_route :get, '/customers/1/appointments/completed', 
                     :controller => 'appointments', :action => 'index', :customer_id => 1, :type => 'work', :state => 'completed'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company, with 2 managers
    @owner        = Factory(:user, :name => "Owner")
    @owner.email_addresses.create(:address => 'owner@walnutcalendar.com')
    @manager      = Factory(:user, :name => "Manager")
    @manager.email_addresses.create(:address => 'manager@walnutcalendar.com')
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    @manager.grant_role('company manager', @company)
    # create providers, with email addresses
    @johnny       = Factory(:user, :name => "Johnny")
    @johnny.email_addresses.create(:address => 'johnny@walnutcalendar.com')
    @company.user_providers.push(@johnny)
    @mary         = Factory(:user, :name => "Mary")
    @mary.email_addresses.create(:address => 'mary@walnutcalendar.com')
    @company.user_providers.push(@mary)
    # create a work service, and assign johnny and mary as service providers
    @haircut      = Factory.build(:work_service, :duration => 30.minutes, :name => "Haircut", :price => 1.00)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    @haircut.user_providers.push(@mary)
    @blowdry      = Factory.build(:work_service, :duration => 30.minutes, :name => "Blow Dry", :price => 1.00)
    @company.services.push(@blowdry)
    @blowdry.user_providers.push(@johnny)
    @blowdry.user_providers.push(@mary)
    @johnny.reload
    @mary.reload
    @company.reload
    # get company free service
    @free_service = @company.free_service
    # create a customer, with an email address
    @customer     = Factory(:user, :name => "Customer")
    @customer.email_addresses.create(:address => 'customer@walnutcalendar.com')
    # stub current company
    @controller.stubs(:current_company).returns(@company)
    # set the request hostname
    @request.host = "www.walnutcalendar.com"
  end

  #
  # Single date appointment tests
  #
  context "with free time on a single date" do
    setup do
      # create free time from 9 am to 11 am local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
      @appt_datetime  = @time_range.start_at.in_time_zone.to_s(:appt_schedule)
    end
    
    context "delete free time with no work appointments" do
      setup do
        delete :destroy, :id => @free_appt.id
      end
      
      should_change("Appointment.count", :by => -1) { Appointment.count }
    end
  
    context "new work appointment as guest" do
      setup do
        # book a haircut with johnny during his free time
        get :new,
            :provider_type => 'users', :provider_id => @johnny.id, :service_id => @haircut.id, :start_at => @appt_datetime,
            :duration => @haircut.duration, :mark_as => 'work'
      end
  
      should "not show rpx login" do
        assert_select 'div#rpx_login', 0
      end
  
      should "not show (hidden) peanut login" do
        assert_select 'div.hide#peanut_login', 0
      end
  
      should "not show customer reminder options" do
        assert_select "input#reminder_customer_on", 0
        assert_select "input#reminder_customer_off", 0
      end
  
      should_respond_with :success
      should_render_template 'appointments/new.html.haml'
    end
  
    context "new work appointment as customer" do
      context "with no email address" do
        setup do
          # stub current user
          @controller.stubs(:current_user).returns(@customer)
          # book a haircut with johnny during his free time
          get :new, 
              :provider_type => 'users', :provider_id => @johnny.id, :service_id => @haircut.id, :start_at => @appt_datetime, 
              :duration => @haircut.duration, :mark_as => 'work'
        end
      
        should_assign_to :appointment, :class => Appointment
        should_assign_to(:service) { @haircut }
        should_assign_to(:duration) { 30.minutes }
        should_assign_to(:provider) { @johnny }
        should_assign_to(:customer) { @customer }
        should_assign_to(:appt_date) { @time_range.start_at.in_time_zone.to_s(:appt_schedule_day) }
        should_assign_to(:appt_time_start_at) { "0900" }
        should_assign_to(:appt_time_end_at) { "0930" }
      
        should "not show customer reminder options" do
          assert_select "input#reminder_customer_on", 0
          assert_select "input#reminder_customer_off", 0
        end
      
        should_respond_with :success
        should_render_template 'appointments/new.html.haml'
      end
    end
  end
  
  context "create free appointment" do
    context "without privilege 'update calendars'" do
      setup do
        @controller.stubs(:current_user).returns(@customer)
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        post :create_free,
             {:date => "20090201", :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}"}
      end
  
      should_redirect_to("unauthorized_path") { unauthorized_path }
    end
    
    context "for a single date" do
      context "with times for start_at and end_at" do
        setup do
          # have johnny create free appointments on his calendar
          @controller.stubs(:current_user).returns(@johnny)
          @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
          post :create_free,
               {:date => "20090201", :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => @johnny.id}
        end
  
        should_change("Appointment.count", :by => 1) { Appointment.count }
  
        should_assign_to(:service) { @free_service }
        should_assign_to(:provider) { @johnny }
        should_assign_to(:start_at)  { "0900" }
        should_assign_to(:end_at) { "1100" }
        should_assign_to(:mark_as) { "free" }
  
        should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar?highlight=20090201" }
      end

      context "with datetimes for start_at and end_at" do
        setup do
          # have johnny create free appointments on his calendar
          @controller.stubs(:current_user).returns(@johnny)
          @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
          post :create_free,
               {:date => "20090201", :start_at => "20090201T0900", :end_at => "20090201T1100", :provider_type => "users", :provider_id => @johnny.id}
        end
  
        should_change("Appointment.count", :by => 1) { Appointment.count }
  
        should_assign_to(:service) { @free_service }
        should_assign_to(:provider) { @johnny }
        should_assign_to(:start_at)  { "0900" }
        should_assign_to(:end_at) { "1100" }
        should_assign_to(:mark_as) { "free" }
  
        should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar?highlight=20090201" }
      end
    end
  
     context "for a block of dates" do
       setup do
         # have johnny create free appointments on his calendar
         @controller.stubs(:current_user).returns(@johnny)
         post :create_block,
              {:dates => ["20090201", "20090203"], :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => @johnny.id}
       end
  
       should_change("Appointment.count", :by => 2) { Appointment.count }
  
       should_assign_to(:service) { @free_service }
       should_assign_to(:provider) { @johnny }
       should_assign_to(:start_at) { "0900" }
       should_assign_to(:end_at) { "1100" }
       should_assign_to(:mark_as)  { "free" }
  
       should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
     end
  end
  
  #
  # Appointment block tests
  #
  context "get new block appointments for provider calendar" do
    context "as another provider" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@mary)
        # stub calendar markings
        @controller.stubs(:build_calendar_markings).returns(Hash.new)
        get :new_block, :provider_type => 'users', :provider_id => @johnny.id
      end

      should_redirect_to("unauthorized_path") { unauthorized_path }
      should_set_the_flash_to /You are not authorized/
    end
    
    context "as provider" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@johnny)
        # stub calendar markings
        @controller.stubs(:build_calendar_markings).returns(Hash.new)
        get :new_block, :provider_type => 'users', :provider_id => @johnny.id
      end

      should_assign_to(:provider) { @johnny }
      should_assign_to :providers, :class => Array
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to :daterange, :class => DateRange

      should_respond_with :success
      should_render_template 'appointments/edit_block.html.haml'
    end
  end
  
  #
  # Recurring appointment tests
  #
  context "get new weekly appointments for provider calendar" do
    context "as another provider" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@mary)
        # stub calendar markings
        @controller.stubs(:build_calendar_markings).returns(Hash.new)
        get :new_weekly, :provider_type => 'users', :provider_id => @johnny.id
      end
  
      should_redirect_to("unauthorized_path") { unauthorized_path }
      should_set_the_flash_to /You are not authorized/
    end
    
    context "as the provider" do
      setup do
        add_mary_and_johnny_as_providers
        @controller.stubs(:current_user).returns(@johnny)
        # stub calendar markings
        @controller.stubs(:build_calendar_markings).returns(Hash.new)
        get :new_weekly, :provider_type => 'users', :provider_id => @johnny.id
      end

      should_assign_to(:provider) { @johnny }
      should_assign_to :providers, :class => Array
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to :daterange, :class => DateRange

      should_respond_with :success
      should_render_template 'appointments/edit_weekly.html.haml'
    end
  end

  context "create weekly schedule" do
    context "with no end date" do
      setup do
        # have johnny create free appointments on his calendar
        @controller.stubs(:current_user).returns(@johnny)
        post :create_weekly,
             {:freq => 'weekly', :byday => 'mo,tu', :dstart => "20090201", :tstart => "090000", :tend => "110000", :until => '',
              :provider_type => "users", :provider_id => "#{@johnny.id}"}
      end
    
      should_change("Appointment.recurring.count", :by => 1) { Appointment.recurring.count }
      should_change("Appointment.count", :by => 1) { Appointment.count }
    
      should_assign_to(:freq) { "WEEKLY" }
      should_assign_to(:byday) { "MO,TU" }
      should_assign_to(:dtstart) { "20090201T090000" }
      should_assign_to(:dtend) { "20090201T110000" }
      should_assign_to(:recur_rule) { "FREQ=WEEKLY;BYDAY=MO,TU" }
      should_assign_to(:provider) { @johnny }

      should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }

      context "and create a conflicting weekly schedule" do
        setup do
          @controller.stubs(:current_user).returns(@johnny)
          post :create_weekly,
               {:freq => 'weekly', :byday => 'mo,tu', :dstart => "20090201", :tstart => "100000", :tend => "120000", :until => '',
                :provider_type => "users", :provider_id => "#{@johnny.id}"}
        end
        
        should_not_change("Appointment.recurring.count") { Appointment.recurring.count }
        should_not_change("Appointment.count") { Appointment.count }
        should_set_the_flash_to /This time conflicts with existing availability/
      end
    end
    
    context "with an end date" do
      setup do
        # have johnny create free appointments on his calendar
        @controller.stubs(:current_user).returns(@johnny)
        post :create_weekly,
             {:freq => 'weekly', :byday => 'mo,tu', :dstart => "20090201", :tstart => "090000", :tend => "110000", :until => '20090515',
              :provider_type => "users", :provider_id => "#{@johnny.id}"}
      end

      should_change("Appointment.recurring.count", :by => 1) { Appointment.recurring.count }
      should_change("Appointment.count", :by => 1) { Appointment.count }

      should_assign_to(:freq) { "WEEKLY" }
      should_assign_to(:byday) { "MO,TU" }
      should_assign_to(:dtstart) { "20090201T090000" }
      should_assign_to(:dtend) { "20090201T110000" }
      should_assign_to(:recur_rule) { "FREQ=WEEKLY;BYDAY=MO,TU;UNTIL=20090515T000000Z" }
      should_assign_to(:provider) { @johnny }

      should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
    end
  end
  
  context "create work appointment for a single date with no free time" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @start_at       = "#{@today}T1000"
      @duration       = 120.minutes
    end
    
    context "as a customer requesting force add" do
      setup do
        # create work appointment as customer
        @controller.stubs(:current_user).returns(@customer)
        # create work appointment, today from 10 am to 12 pm local time
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id, :customer_id => @customer.id, :force => 1}
      end
    
      # should not add the appointment
      should_not_change("Appointment.count") { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }

      should_redirect_to("user history page" ) { "/history" }
    end

    context "as a provider requesting force add in their own calendar" do
      setup do
        @controller.stubs(:current_user).returns(@johnny)
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
             :service_id => @haircut.id, :customer_id => @customer.id, :force => 1}
      end
    
      # should add the appointment
      should_change("Appointment.count", :by => 1) { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }
      should_assign_to(:appointments)

      should_redirect_to("provider's calendar path, with highlight date" ) { "/users/#{@johnny.id}/calendar?highlight=#{@today}" }
    end
    
    context "as a provider requesting force add in another provider's calendar" do
      setup do
        @controller.stubs(:current_user).returns(@mary)
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
             :service_id => @haircut.id, :customer_id => @customer.id, :force => 1}
      end

      # should not add the appointment
      should_not_change("Appointment.count") { Appointment.count }

      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }
      should_assign_to(:appointments)

      should_redirect_to("provider's calendar path" ) { "/users/#{@johnny.id}/calendar" }
    end
    
    context "as an owner without requesting to force add" do
      setup do
        # create work appointment as customer
        @controller.stubs(:current_user).returns(@owner)
        # create work appointment, today from 10 am to 12 pm local time
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id, :customer_id => @customer.id}
      end
    
      # should not add the appointment
      should_not_change("Appointment.count") { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }
      should_assign_to(:appointments)
    
      should_redirect_to("provider's calendar path" ) { "/users/#{@johnny.id}/calendar" }
    end
    
    context "as an owner requesting not to force add" do
      setup do
        # create work appointment as customer
        @controller.stubs(:current_user).returns(@owner)
        # create work appointment, today from 10 am to 12 pm local time
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id, :customer_id => @customer.id, :force => 0}
      end
    
      # should fail to add the appointment
      should_not_change("Appointment.count") { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }

      should_respond_with :redirect
      should_redirect_to("provider's calendar path" ) { "/users/#{@johnny.id}/calendar" }
    end

    context "as an owner with request to force add" do
      setup do
        # create work appointment as customer
        @controller.stubs(:current_user).returns(@owner)
        # create work appointment, today from 10 am to 12 pm local time
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id, :customer_id => @customer.id, :force => 1}
      end

      # should succeed in adding the appointment
      should_change("Appointment.count", :by => 1) { Appointment.count }

      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }

      should_respond_with :redirect
      should_redirect_to("provider's calendar path, with highlight date" ) { "/users/#{@johnny.id}/calendar?highlight=#{@today}" }
    end
  end

  context "create work appointment for a single date with free time, replacing free time" do
    setup do
      # create free time from 9 am to 11 am local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
      @start_at       = "#{@today}T0900"
      @duration       = 2.hours
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)
      # create work appointment, today from 9 am to 11 am
      @request.env['HTTP_REFERER'] = '/users/0/calendar'
      post :create_work,
           {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :customer_id => @customer.id}
      @free_appt.reload
    end
  
    # free appointment and work appointment coexist
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    # There should be no available capacity slots
    should "have no capacity slots" do
      assert_equal 0, CapacitySlot.count
    end
  
    should_assign_to(:service) { @haircut }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:customer) { @customer }
    should_assign_to(:start_at)  { @start_at }
    should_not_assign_to(:end_at)
    should_assign_to(:duration) { 120.minutes }
    should_assign_to(:mark_as) { "work" }
      
    should "have appointment duration of 120 minutes" do
      assert_equal 120.minutes, assigns(:appointment).duration
      assert_equal 9, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 11, assigns(:appointment).end_at.hour
      assert_equal 0, assigns(:appointment).end_at.min
    end

    should_redirect_to("history path") { "/history" }
  end

  context "create work appointment for a single date with free time, splitting free time" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
      @start_at       = "#{@today}T1000"
      @duration       = 30.minutes
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)  
      # create work appointment, today from 10 am to 10:30 am local time
      @request.env['HTTP_REFERER'] = '/users/0/calendar'
      post :create_work,
           {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :customer_id => @customer.id}
      @free_appt.reload
    end
  
    # free appointment and work appointment coexist
    should_change("Appointment.count", :by => 2) { Appointment.count }
  
    # There should be two available capacity slots
    should "have two capacity slots" do
      assert_equal 2, CapacitySlot.count
    end
  
    should_assign_to(:service) { @haircut }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:customer) { @customer }
    should_assign_to(:start_at)  { @start_at }
    should_not_assign_to(:end_at)
    should_assign_to(:duration) { 30.minutes }
    should_assign_to(:mark_as) { "work" }
    
    should "have appointment duration of 30 minutes" do
      assert_equal 30.minutes, assigns(:appointment).duration
      assert_equal 10, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 10, assigns(:appointment).end_at.hour
      assert_equal 30, assigns(:appointment).end_at.min
    end

    should_redirect_to("history path") { "/history" }
  end
  
  context "create work appointment for a single date with free time, using a custom duration" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
      @start_at       = "#{@today}T1000"
      @duration       = 120.minutes
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)
      # create work appointment, today from 10 am to 12 pm local time
      @request.env['HTTP_REFERER'] = '/users/0/calendar'
      post :create_work,
           {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :customer_id => @customer.id}
      @free_appt.reload
    end
  
    # free appointment should coexist with 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have two capacity slots" do
      assert_equal 2, CapacitySlot.count
    end
  
    should_assign_to(:service) { @haircut }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:customer) { @customer }
    should_assign_to(:start_at) { @start_at }
    should_not_assign_to(:end_at)
    should_assign_to(:duration)  { 120.minutes }
    should_assign_to(:mark_as) { "work" }
    should_assign_to :appointment
  
    should "have appointment duration of 120 minutes" do
      assert_equal 120.minutes, assigns(:appointment).duration
      assert_equal 10, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 12, assigns(:appointment).end_at.hour
      assert_equal 0, assigns(:appointment).end_at.min
    end

    should_redirect_to("history path") { "/history" }
  end

  context "create work appointment" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
  
      @start_at       = "#{@today}T1000"
      @duration       = 120.minutes
    end
    
    context "with a new customer signup" do
      setup do
        # create work appointment as anonymous user
        @controller.stubs(:current_user).returns(nil)
        # create work appointment, today from 10 am to 12 pm local time
        post :create_work,
             {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id,
              :customer => {:name => "Sanjay", :password => 'sanjay', :password_confirmation => 'sanjay',
                            :email_addresses_attributes => [{:address => "sanjay@walnut.com"}]}
             }
      end
      
      should_redirect_to("unauthorized") { unauthorized_path }
    end
  
    context "with appointment confirmations" do
      context "to nobody" do
        setup do
          @company.preferences[:work_appointment_confirmation_customer] = '0'
          @company.preferences[:work_appointment_confirmation_manager]  = '0'
          @company.preferences[:work_appointment_confirmation_provider] = '0'
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id}
        end
        
        # should not send any appt confirmations
        should_not_change("message count") { Message.count }
        should_not_change("message topic") { MessageTopic.count }
        should_not_change("delayed job count") { Delayed::Job.count }
      end
  
      context "to customer only" do
        setup do
          @company.preferences[:work_appointment_confirmation_customer] = '1'
          @company.preferences[:work_appointment_confirmation_manager]  = '0'
          @company.preferences[:work_appointment_confirmation_provider] = '0'
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id}
        end
  
        # should send appt confirmation to customer
        should_change("message count", :by => 1) { Message.count }
        should_change("message topic", :by => 1) { MessageTopic.count }
        should_change("delayed job count", :by => 1) { Delayed::Job.count }
  
        should "have appointment confirmation addressed to customer" do
          assert_equal 1, MessageRecipient.for_messagable(@customer.primary_email_address).size
        end
      end
  
      context "to provider only" do
        setup do
          @company.preferences[:work_appointment_confirmation_customer] = '0'
          @company.preferences[:work_appointment_confirmation_manager]  = '0'
          @company.preferences[:work_appointment_confirmation_provider] = '1'
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id}
        end
  
        # should send appt confirmation to customer
        should_change("message count", :by => 1) { Message.count }
        should_change("message topic", :by => 1) { MessageTopic.count }
        should_change("delayed job count", :by => 1) { Delayed::Job.count }
  
        should "have appointment confirmation addressed to provider" do
          assert_equal 1, MessageRecipient.for_messagable(@johnny.primary_email_address).size
        end
      end
  
      context "to managers only" do
        setup do
          @company.preferences[:work_appointment_confirmation_customer] = '0'
          @company.preferences[:work_appointment_confirmation_manager]  = '1'
          @company.preferences[:work_appointment_confirmation_provider] = '0'
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id}
        end
  
        # should send appt confirmation to all managers
        should_change("message count", :by => 2) { Message.count }
        should_change("message topic", :by => 2) { MessageTopic.count }
        should_change("delayed job count", :by => 2) { Delayed::Job.count }
  
        should "have appointment confirmation addressed to owner and manager" do
          assert_equal 1, MessageRecipient.for_messagable(@owner.primary_email_address).size
          assert_equal 1, MessageRecipient.for_messagable(@manager.primary_email_address).size
        end
      end
  
      context "to customer and managers" do
        setup do
          @company.preferences[:work_appointment_confirmation_customer] = '1'
          @company.preferences[:work_appointment_confirmation_manager]  = '1'
          @company.preferences[:work_appointment_confirmation_provider] = '0'
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id}
        end
  
        # should send appt confirmation to customer and all managers
        should_change("message count", :by => 3) { Message.count }
        should_change("message topic", :by => 3) { MessageTopic.count }
        should_change("delayed job count", :by => 3) { Delayed::Job.count }
  
        should "have appointment confirmation addressed to customer" do
          assert_equal 1, MessageRecipient.for_messagable(@customer.primary_email_address).size
        end
  
        should "have appointment confirmation addressed to owner and manager" do
          assert_equal 1, MessageRecipient.for_messagable(@owner.primary_email_address).size
          assert_equal 1, MessageRecipient.for_messagable(@manager.primary_email_address).size
        end
      end
  
      context "with company email text" do
        setup do
          @email_text = "Appointment cancelations are allowed up to 24 hours before your appointment."
          @company.preferences[:work_appointment_confirmation_customer] = '1'
          @company.preferences[:email_text] = @email_text
          @company.save
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id}
        end
  
        should_assign_to(:confirmations, :class => Array)
  
        should "have company email text as part of message body" do
          @message = assigns(:confirmations).first
          assert_match /#{@email_text}/, @message.body
        end
      end
  
      context "with provider email text" do
        setup do
          @provider_email_text = "No credit cards, cash only."
          @company.preferences[:work_appointment_confirmation_customer] = '1'
          @company.save
          @johnny.preferences[:provider_email_text] = @provider_email_text
          @johnny.save
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => @johnny.id,
                :service_id => @haircut.id, :customer_id => @customer.id}
        end
  
        should_assign_to(:confirmations, :class => Array)
  
        should "have provider email text as part of message body" do
          @message = assigns(:confirmations).first
          assert_match /#{@provider_email_text}/, @message.body
        end
      end
  
      context "with company and provider email text" do
        setup do
          @company_email_text  = "Appointment cancelations are allowed up to 24 hours before your appointment."
          @provider_email_text = "No credit cards, cash only."
          @company.preferences[:work_appointment_confirmation_customer] = '1'
          @company.preferences[:email_text] = @company_email_text
          @company.save
          @johnny.preferences[:provider_email_text] = @provider_email_text
          @johnny.save
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id}
        end
  
        should_assign_to(:confirmations, :class => Array)
  
        should "have company email text as part of message body" do
          @message = assigns(:confirmations).first
          assert_match /#{@company_email_text}\n\n#{@provider_email_text}/, @message.body
        end
      end
    end
  
    context "with appointment customer reminders" do
      context "turned on" do
        setup do
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id, :preferences_reminder_customer => '1'}
        end
  
        should "set appointment customer reminder to 1" do
          @appointment = Appointment.find(assigns(:appointment).id)
          assert_equal 1, @appointment.preferences[:reminder_customer].to_i
        end
      end
  
      context "turned off" do
        setup do
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          @request.env['HTTP_REFERER'] = '/users/0/calendar'
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id, :preferences_reminder_customer => '0'}
        end
  
        should "set appointment customer reminder to 0" do
          @appointment = Appointment.find(assigns(:appointment).id)
          assert_equal 0, @appointment.preferences[:reminder_customer].to_i
        end
      end
    end
  end

  context "update free appointment" do
    setup do
      # create free time from 10 am to 12 pm
      @today        = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range   = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @duration     = 2.hours
      @free_appt    = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
      assert @free_appt.valid?
    end

    context "without 'update calendar' privilege" do
      setup do
        @request.env['HTTP_REFERER'] = '/users/0/calendar'
        put :update, {:id => @free_appt.id, :mark_as => 'free', :force => '1',
                      :service_id => @free_service.id, :provider_type => "users", :provider_id => @johnny.id,
                      :start_at => @free_appt.start_at.to_s(:appt_schedule), :end_at => @free_appt.end_at.to_s(:appt_schedule)}
      end

      should_redirect_to("unauthorized") { "/unauthorized" }
    end

    context "change start time" do
      setup do
        @start_at = @free_appt.start_at
        @end_at   = @free_appt.end_at
        @request.env['HTTP_REFERER'] = '/users/0/calendar'
        @controller.stubs(:current_user).returns(@owner)
        put :update, {:id => @free_appt.id, :mark_as => 'free', :force => '1', :provider_type => "users", :provider_id => @johnny.id,
                      :start_at => (@free_appt.start_at+2.hours).to_s(:appt_schedule), :end_at => (@free_appt.end_at+2.hours).to_s(:appt_schedule)}
      end

      should_assign_to(:appointment) { @free_appt }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:service) { @free_service }
      
      should "not change appointment customer" do
        assert_nil @free_appt.reload.customer_id
      end

      should "change appointment start time" do
        assert_equal @start_at+2.hours, @free_appt.reload.start_at
      end

      should "change appointment end time" do
        assert_equal @end_at+2.hours, @free_appt.reload.end_at
      end

      should_not_change("appointment duration") { @free_appt.reload.duration }

      should_redirect_to("referer") { "/users/0/calendar?highlight=#{@free_appt.start_at.to_s(:appt_schedule_day)}" }
    end

    context "change duration" do
      setup do
        @start_at = @free_appt.start_at
        @end_at   = @free_appt.end_at
        @request.env['HTTP_REFERER'] = '/users/0/calendar'
        @controller.stubs(:current_user).returns(@owner)
        put :update, {:id => @free_appt.id, :mark_as => 'free', :force => '1', :provider_type => "users", :provider_id => @johnny.id,
                      :start_at => (@free_appt.start_at+1.hour).to_s(:appt_schedule), :end_at => (@free_appt.end_at+3.hours).to_s(:appt_schedule)}
      end

      should "change appointment start time" do
        assert_equal @start_at+1.hour, @free_appt.reload.start_at
      end

      should "change appointment end time" do
        assert_equal @end_at+3.hour, @free_appt.reload.end_at
      end

      should_change("appointment duration", :by => 2.hours) { @free_appt.reload.duration }
    end
  end

  context "update work appointment" do
    setup do
      # create free time from 10 am to 12 pm
      @today        = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range   = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt    = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
      # create work appointment
      @options      = {:start_at => @free_appt.start_at}
      @work_appt    = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @customer, @options)
      assert @work_appt.valid?
    end

    context "without 'update calendar' privilege" do
      setup do
        @request.env['HTTP_REFERER'] = '/users/0/calendar'
        put :update, {:id => @work_appt.id, :mark_as => 'work', :force => '1',
                      :service_id => @haircut.id, :duration => @haircut.duration, :customer_id => @customer.id,
                      :start_at => @work_appt.start_at.to_s(:appt_schedule), :provider_type => "users", :provider_id => @mary.id}
      end

      should_redirect_to("unauthorized") { "/unauthorized" }
    end

    context "change provider" do
      setup do
        @request.env['HTTP_REFERER'] = '/users/0/calendar'
        @controller.stubs(:current_user).returns(@owner)
        put :update, {:id => @work_appt.id, :mark_as => 'work', :force => '1',
                      :service_id => @haircut.id, :duration => @haircut.duration, :customer_id => @customer.id,
                      :start_at => @work_appt.start_at.to_s(:appt_schedule), :provider_type => "users", :provider_id => @mary.id}
      end

      should_assign_to(:appointment) { @work_appt }
      should_assign_to(:provider) { @mary }
      should_assign_to(:service) { @haircut }
      should_assign_to(:customer) { @customer }

      should "change appointment provider" do
        assert_equal @mary, @work_appt.reload.provider
      end

      should_redirect_to("referer") { "/users/0/calendar?highlight=#{@work_appt.start_at.to_s(:appt_schedule_day)}" }
    end

    context "change service" do
      setup do
        @request.env['HTTP_REFERER'] = '/openings'
        @controller.stubs(:current_user).returns(@owner)
        put :update, {:id => @work_appt.id, :mark_as => 'work', :force => '1',
                      :service_id => @blowdry.id, :duration => @blowdry.duration, :customer_id => @customer.id,
                      :start_at => @work_appt.start_at.to_s(:appt_schedule), :provider_type => "users", :provider_id => @johnny.id}
      end

      should_assign_to(:appointment) { @work_appt }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:service) { @blowdry }
      should_assign_to(:customer) { @customer }

      should "change appointment service" do
        assert_equal @blowdry, @work_appt.reload.service
      end
    end

    context "change customer" do
      setup do
        @request.env['HTTP_REFERER'] = '/openings'
        @customer2 = Factory(:user, :name => "Customer 2")
        @controller.stubs(:current_user).returns(@owner)
        put :update, {:id => @work_appt.id, :mark_as => 'work', :force => '1',
                      :service_id => @haircut.id, :duration => @haircut.duration, :customer_id => @customer2.id,
                      :start_at => @work_appt.start_at.to_s(:appt_schedule), :provider_type => "users", :provider_id => @johnny.id}
      end

      should_assign_to(:appointment) { @work_appt }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:service) { @haircut }
      should_assign_to(:customer) { @customer2 }

      should "change appointment customer" do
        assert_equal @customer2, @work_appt.reload.customer
      end
    end

    context "change start time" do
      setup do
        @request.env['HTTP_REFERER'] = '/openings'
        @start_at = @work_appt.start_at
        @end_at   = @work_appt.end_at
        @controller.stubs(:current_user).returns(@owner)
        put :update, {:id => @work_appt.id, :mark_as => 'work', :force => '1',
                      :service_id => @haircut.id, :duration => @haircut.duration, :customer_id => @customer.id,
                      :start_at => (@work_appt.start_at + 2.hours).to_s(:appt_schedule), :provider_type => "users", :provider_id => @johnny.id}
      end

      should_assign_to(:appointment) { @work_appt }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:service) { @haircut }
      should_assign_to(:customer) { @customer2 }

      should "change appointment start time" do
        assert_equal @start_at+2.hours, @work_appt.reload.start_at
      end

      should "change appointment end time" do
        assert_equal @end_at+2.hours, @work_appt.reload.end_at
      end

      should_not_change("appointment duration") { @work_appt.reload.duration }
    end

    context "change duration" do
      setup do
        @request.env['HTTP_REFERER'] = '/openings'
        @start_at = @work_appt.start_at
        @end_at   = @work_appt.end_at
        @controller.stubs(:current_user).returns(@owner)
        put :update, {:id => @work_appt.id, :mark_as => 'work', :force => '1',
                      :service_id => @haircut.id, :duration => @haircut.duration + 1.hour, :customer_id => @customer.id,
                      :start_at => @work_appt.start_at.to_s(:appt_schedule), :provider_type => "users", :provider_id => @johnny.id}
      end

      should_assign_to(:appointment) { @work_appt }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:service) { @haircut }
      should_assign_to(:customer) { @customer2 }

      should "not change appointment start time" do
        assert_equal @start_at, @work_appt.reload.start_at
      end

      should "change appointment end time" do
        assert_equal @end_at+60.minutes, @work_appt.reload.end_at
      end

      should_change("appointment duration", :by => 1.hour) { @work_appt.reload.duration }
    end
  end

  context "cancel free appointment" do
    setup do
      # create free time from 10 am to 12 pm
      @today        = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range   = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt    = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
      # find free slot that corresponds to free appointmen t
      @free_slot    = CapacitySlot.find(:first, :conditions => {:start_at => @free_appt.start_at})
    end

    context "without 'update calendar' privilege" do
      setup do
        @request.env['HTTP_REFERER'] = '/openings'
        get :cancel, :id => @free_appt.id
      end

      should_redirect_to("unauthorized") { "/unauthorized" }
    end

    context "with privileges" do
      setup do
        @request.env['HTTP_REFERER'] = "/users/#{@johnny.id}/calendar"
        @controller.stubs(:current_user).returns(@owner)
        get :cancel, :id => @free_appt.id
      end

      should "change appointment state to canceled" do
        assert_equal "canceled", @free_appt.reload.state
      end

      should_change("capacity slot count", :by => -1) { CapacitySlot.count}
      should "remove free slot" do
        assert_nil CapacitySlot.find_by_id(@free_slot.id)
      end

      should_redirect_to("referer") { "/users/#{@johnny.id}/calendar?highlight=#{@free_appt.start_at.to_s(:appt_schedule_day)}" }
    end
  end

  context "cancel work appointment" do
    setup do
      # create free time from 10 am to 12 pm
      @today        = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range   = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt    = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @johnny, :time_range => @time_range)
      # create work appointment
      @options      = {:start_at => @free_appt.start_at}
      @work_appt    = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @customer, @options)
      assert @work_appt.valid?
      # find free slot that starts after work appointment
      @free_slot    = CapacitySlot.find(:first, :conditions => {:start_at => @work_appt.start_at + @haircut.duration})
    end

    context "without 'update calendar' privilege" do
      setup do
        @request.env['HTTP_REFERER'] = '/openings'
        get :cancel, :id => @work_appt.id
      end

      should_redirect_to("unauthorized") { "/unauthorized" }
    end

    context "with privileges" do
      setup do
        @request.env['HTTP_REFERER'] = '/openings'
        @controller.stubs(:current_user).returns(@owner)
        get :cancel, :id => @work_appt.id
      end

      should "change appointment state to canceled" do
        assert_equal "canceled", @work_appt.reload.state
      end

      should_not_change("capacity slot count") { CapacitySlot.count}
      should_change("free slot duration", :by => 30.minutes) { @free_slot.reload.duration }

      should_redirect_to("referer") { "/openings?highlight=#{@work_appt.start_at.to_s(:appt_schedule_day)}" }
    end
  end
  
end
