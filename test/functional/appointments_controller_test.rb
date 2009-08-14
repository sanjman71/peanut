require 'test/test_helper'
require 'test/factories'

class AppointmentsControllerTest < ActionController::TestCase

  # schedule a waitlist appointment for a specific provider, with a date range
  should_route :get, 'book/wait/users/1/services/5/20090101..20090201',
               :controller => 'appointments', :action => 'new', :provider_type => 'users', :provider_id => 1, :service_id => 5, 
               :start_date => '20090101', :end_date => '20090201', :mark_as => 'wait'
  should_route :post, 'book/wait/users/1/services/5/20090101..20090201',
               :controller => 'appointments', :action => 'create_wait', :provider_type => 'users', :provider_id => 1, :service_id => 5, 
               :start_date => '20090101', :end_date => '20090201', :mark_as => 'wait'
  
  # schedule a work apppointment for a specific provider, service and duration
  should_route :get, 'book/work/users/3/services/3/60/20090303T113000',
               :controller => 'appointments', :action => 'new', :provider_type => 'users', :provider_id => 3, :service_id => 3, 
               :duration => 60, :start_at => '20090303T113000', :mark_as => 'work'
  should_route :post, 'book/work/users/3/services/3/60/20090303T113000',
               :controller => 'appointments', :action => 'create_work', :provider_type => 'users', :provider_id => 3, :service_id => 3, 
               :duration => 60, :start_at => '20090303T113000', :mark_as => 'work'

  # create free time
  should_route  :post, '/users/3/calendar/free', 
                :controller => 'appointments', :action => 'create_free', :provider_type => 'users', :provider_id => 3
  should_route  :post, '/users/3/calendar/block', 
                :controller => 'appointments', :action => 'create_block', :provider_type => 'users', :provider_id => 3
  should_route  :post, '/users/3/calendar/weekly', 
                :controller => 'appointments', :action => 'create_weekly', :provider_type => 'users', :provider_id => 3
  
  # show an appointment
  should_route :get, '/appointments/1', :controller => 'appointments', :action => 'show', :id => 1
  
  # show work appointments by state
  should_route :get, '/appointments/upcoming', :controller => 'appointments', :action => 'index', :type => 'work', :state => 'upcoming'
  
  # show a customer's work appointments, with an optional state parameter
  should_route :get, '/customers/1/appointments', :controller => 'appointments', :action => 'index', :customer_id => 1, :type => 'work'
  should_route :get, '/customers/1/appointments/completed', 
                     :controller => 'appointments', :action => 'index', :customer_id => 1, :type => 'work', :state => 'completed'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @controller   = AppointmentsController.new
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @johnny, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription, :users => [@owner])
    # create provider
    @johnny       = Factory(:user, :name => "Johnny")
    @company.providers.push(@johnny)
    @company.reload
    # create a work service, and assign johnny as a service provider
    @haircut      = Factory(:work_service, :duration => 30, :name => "Haircut", :users => [@johnny], :price => 1.00)
    @company.services.push(@haircut)
    @company.reload
    # get company free service
    @free_service = @company.free_service
    # create a customer
    @customer     = Factory(:user, :name => "Customer")
    # stub current company
    @controller.stubs(:current_company).returns(@company)
    # set the request hostname
    @request.host = "www.peanut.com"
  end

  context "build work appointment for a single date with free time" do
    context "without being logged in" do
      setup do
        # create free time from 9 am to 11 am local time
        @today          = Time.now.utc.to_s(:appt_schedule_day)
        @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
        @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
        @appt_datetime  = @time_range.start_at.in_time_zone.to_s(:appt_schedule)

        # book a haircut with johnny during his free time
        get :new, 
            :provider_type => 'users', :provider_id => @johnny.id, :service_id => @haircut.id, :start_at => @appt_datetime, 
            :duration => @haircut.duration, :mark_as => 'work'
      end
    
      should_respond_with :redirect
      should_redirect_to("login_path") { login_path }
    end

    context "being logged in as a customer" do
      setup do
        # create free time from 9 am to 11 am local time
        @today          = Time.now.utc.to_s(:appt_schedule_day)
        @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
        @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
        @appt_datetime  = @time_range.start_at.in_time_zone.to_s(:appt_schedule)
      
        # stub current user
        @controller.stubs(:logged_in?).returns(true)
        @controller.stubs(:current_user).returns(@customer)
        ActionView::Base.any_instance.stubs(:current_user).returns(@customer)
      
        # book a haircut with johnny during his free time
        get :new, 
            :provider_type => 'users', :provider_id => @johnny.id, :service_id => @haircut.id, :start_at => @appt_datetime, 
            :duration => @haircut.duration, :mark_as => 'work'
      end

      should_respond_with :success
      should_render_template 'appointments/new.html.haml'
    
      should_assign_to :appointment, :class => Appointment
      should_assign_to(:service) { @haircut }
      should_assign_to(:duration) { 30 }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:customer) { @customer }
      should_assign_to(:appt_date) { @time_range.start_at.in_time_zone.to_s(:appt_schedule_day) }
      should_assign_to(:appt_time_start_at) { "0900" }
      should_assign_to(:appt_time_end_at) { "0930" }
    end
  end
  
  context "create free appointment without privilege ['update calendars']" do
    setup do
      @controller.stubs(:current_user).returns(@customer)
      post :create_free,
           {:dates => ["20090201", "20090203"], :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @free_service.id, :mark_as => 'free'}
    end
    
    should_not_change("Appointment.count") { Appointment.count }
    should_respond_with :redirect
    should_redirect_to("unauthorized_path") { unauthorized_path }
  end

  context "create free appointment for a single date" do
    setup do
      # have johnny create free appointments on his calendar
      @controller.stubs(:current_user).returns(@johnny)
      post :create_free,
           {:dates => "20090201", :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}", 
            :service_id => @free_service.id, :mark_as => 'free'}
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
    
    should_assign_to(:service) { @free_service }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:start_at)  { "0900" }
    should_assign_to(:end_at) { "1100" }
    should_assign_to(:mark_as) {"free" }

    should_respond_with :redirect
    should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
  end

  context "create free appointment for a block of dates" do
    setup do
      # have johnny create free appointments on his calendar
      @controller.stubs(:current_user).returns(@johnny)
      post :create_block,
           {:dates => ["20090201", "20090203"], :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @free_service.id, :mark_as => 'free'}
    end
    
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should_assign_to(:service) { @free_service }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:start_at) { "0900" }
    should_assign_to(:end_at) { "1100" }
    should_assign_to(:mark_as)  { "free" }

    should_respond_with :redirect
    should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
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
      should_assign_to(:free_service) { @free_service }

      should_respond_with :redirect
      should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
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
      should_assign_to(:free_service) { @free_service }

      should_respond_with :redirect
      should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
    end
  end

  context "build work appointment for a single date with free time" do
    context "not logged in" do
      setup do
        # create free time from 9 am to 11 am local time
        @today          = Time.now.utc.to_s(:appt_schedule_day)
        @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
        @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
        @appt_datetime  = @time_range.start_at.to_s(:appt_schedule)

        # book a haircut with johnny during his free time
        get :new, 
            :provider_type => 'users', :provider_id => @johnny.id, :service_id => @haircut.id, :start_at => @appt_datetime, 
            :duration => @haircut.duration, :mark_as => 'work'
      end
    
      should_respond_with :redirect
      should_redirect_to("login_path") { login_path }
    end

    context "logged in as a customer" do
      setup do
        # create free time from 9 am to 11 am local time
        @today          = Time.zone.now.utc.to_s(:appt_schedule_day)
        @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
        @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
        @appt_datetime  = @time_range.start_at.in_time_zone.to_s(:appt_schedule)

        # stub current user
        @controller.stubs(:current_user).returns(@customer)

        # book a haircut with johnny during his free time
        get :new,
            :provider_type => 'users', :provider_id => @johnny.id, :service_id => @haircut.id, :start_at => @appt_datetime, 
            :duration => @haircut.duration, :mark_as => 'work'
      end

      should_respond_with :success
      should_render_template 'appointments/new.html.haml'
    
      should_assign_to :appointment, :class => Appointment
      should_assign_to(:service) { @haircut }
      should_assign_to(:duration) { 30 }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:customer) { @customer }
      should_assign_to(:appt_date) { @time_range.start_at.to_s(:appt_schedule_day) }
      should_assign_to(:appt_time_start_at) { "0900" }
      should_assign_to(:appt_time_end_at) { "0930" }
    end
  end

  context "create work appointment for a single date that has no free time" do
    setup do
      # have johnny create free appointments on his calendar
      @controller.stubs(:current_user).returns(@johnny)
      post :create_work,
           {:dates => "20090201", :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :customer_id => @customer.id, :mark_as => 'work'}
    end
  
    should_not_change("Appointment.count") { Appointment.count }
  
    should_assign_to(:service) { @haircut }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:start_at) { "0900" }
    should_assign_to(:end_at) { "1100" }
    should_assign_to(:mark_as) { "work" }
  
    should_respond_with :redirect
    should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
  end
  
  context "create work appointment for a single date with free time, replacing free time" do
    setup do
      # create free time from 9 am to 11 am local time
      @today          = Time.now.utc.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
  
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)
  
      # create work appointment, today from 9 am to 11 am
      post :create_work,
           {:dates => @today, :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :duration => 120, :customer_id => @customer.id, :mark_as => 'work'}
      @free_appt.reload
    end

    # free appointment and work appointment coexist
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    # There should be no available capacity slots
    should "have no capacity slots" do
      assert_equal 0, @free_appt.capacity_slots.size
    end

    should_assign_to(:service) { @haircut }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:customer) { @customer }
    should_assign_to(:start_at)  { "0900" }
    should_assign_to(:end_at)  { "1100" }
    should_assign_to(:duration) { 120 }
    should_assign_to(:mark_as) { "work" }
  
    should "have appointment duration of 120 minutes" do
      assert_equal 120, assigns(:appointment).duration
      assert_equal 9, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 11, assigns(:appointment).end_at.hour
      assert_equal 0, assigns(:appointment).end_at.min
    end
  
    should_respond_with :redirect
    should_redirect_to("appointment path") { "/appointments/#{assigns(:appointment).id}" }
  end
  
  context "create work appointment for a single date with free time, splitting free time" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.now.utc.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
  
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)
      
      # create work appointment, today from 10 am to 10:30 am local time
      post :create_work,
           {:dates => @today, :start_at => "1000", :end_at => "1030", :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :duration => 30, :customer_id => @customer.id, :mark_as => 'work'}
      @free_appt.reload
    end
    
    # free appointment and work appointment coexist
    should_change("Appointment.count", :by => 2) { Appointment.count }

    # There should be two available capacity slots
      should "have two capacity slots" do
      assert_equal 2, @free_appt.capacity_slots.size
    end
  
    should_assign_to(:service) { @haircut }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:customer) { @customer }
    should_assign_to(:start_at)  { "1000" }
    should_assign_to(:end_at) { "1030" }
    should_assign_to(:duration) { 30 }
    should_assign_to(:mark_as) { "work" }
    
    should "have appointment duration of 30 minutes" do
      assert_equal 30, assigns(:appointment).duration
      assert_equal 10, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 10, assigns(:appointment).end_at.hour
      assert_equal 30, assigns(:appointment).end_at.min
    end
  
    should_respond_with :redirect
    should_redirect_to("appointment path") { "/appointments/#{assigns(:appointment).id}" }
  end
  
  context "create work appointment for a single date with free time, using a custom duration" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.now.utc.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
  
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)
  
      # create work appointment, today from 10 am to 12 pm local time
      post :create_work,
           {:dates => @today, :start_at => "1000", :end_at => "1200", :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :duration => 120, :customer_id => @customer.id, :mark_as => 'work'}
      @free_appt.reload
    end

    # free appointment should coexist with 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have two capacity slots" do
      assert_equal 2, @free_appt.capacity_slots.size
    end

    should_assign_to(:service) { @haircut }
    should_assign_to(:provider) { @johnny }
    should_assign_to(:customer) { @customer }
    should_assign_to(:start_at) { "1000" }
    should_assign_to(:end_at)  { "1200" }
    should_assign_to(:duration)  { 120 }
    should_assign_to(:mark_as) { "work" }
    should_assign_to :appointment
  
    should "have appointment duration of 120 minutes" do
      assert_equal 120, assigns(:appointment).duration
      assert_equal 10, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 12, assigns(:appointment).end_at.hour
      assert_equal 0, assigns(:appointment).end_at.min
    end
  
    should_respond_with :redirect
    should_redirect_to("appointment path") { "/appointments/#{assigns(:appointment).id}" }
  end
  
  context "request a waitlist appointment for a date range" do
    setup do
      # stub the current user and logged_in? state
      @controller.stubs(:logged_in?).returns(true)
      @controller.stubs(:current_user).returns(@customer)
      ActionView::Base.any_instance.stubs(:current_user).returns(@customer)
      
      # build daterange start, end times in utc format
      @start_date_utc = Time.parse("20090201").utc.to_s(:appt_schedule_day)
      @end_date_utc   = Time.parse("20090208").utc.to_s(:appt_schedule_day)
      
      # request a waitlist appointment
      get :new,
          {:start_date => @start_date_utc, :end_date => @end_date_utc, :time => 'anytime', :provider_type => @johnny.tableize, :provider_id => @johnny.id,
           :service_id => @haircut.id, :mark_as => 'wait'}
    end

    should_respond_with :success
    should_render_template 'appointments/new.html.haml'

    should_not_change("Appointment.count") { Appointment.count }

    should_assign_to :daterange
    should_assign_to :appointment
    
    should "be a valid appointment" do
      assert assigns(:appointment).valid?
    end
    
    should "have a waitlist start date of 20090201 and end date of 20090209 (daterange is inclusive)" do
      assert_equal "20090201", assigns(:appointment).start_at.utc.to_s(:appt_schedule_day) # utc format
      assert_equal "20090209", assigns(:appointment).end_at.utc.to_s(:appt_schedule_day) # utc format
    end
  end
  
  context "create waitlist appointment" do
    context "for a service with a specific provider" do
      setup do
        # create waitlist appointment as customer
        @controller.stubs(:current_user).returns(@customer)
  
        # create waitlist appointment
        post :create_wait,
             {:dates => 'Feb 01 2009 - Feb 08 2009', :start_at => "20090201", :end_at => "20090208", :provider_type => @johnny.tableize, :provider_id => @johnny.id,
              :service_id => @haircut.id, :customer_id => @customer.id, :mark_as => 'wait'}
      end
  
      should_change("Appointment.count", :by => 1) { Appointment.count }
  
      should_assign_to(:service) { @haircut }
      should_not_assign_to(:duration)
      should_assign_to(:provider) { @johnny }
      should_assign_to(:customer) { @customer }
      should_assign_to(:mark_as) { "wait" }
      should_assign_to(:appointment)
    
      should_respond_with :redirect
      should_redirect_to("appointment path") { "/appointments/#{assigns(:appointment).id}" }
    end
    
    context "for a service with any service provider" do
      setup do
        # get 'anyone' user
        @anyone = User.anyone
  
        # stub current user
        @controller.stubs(:current_user).returns(@customer)
  
        # create waitlist appointment
        post :create_wait,
             {:dates => 'Feb 01 2009 - Feb 08 2009', :start_at => "20090201", :end_at => "20090208", :provider_type => @anyone.tableize, :provider_id => @anyone.id,
              :service_id => @haircut.id, :customer_id => @customer.id, :mark_as => 'wait'}
      end
  
      should_change("Appointment.count", :by => 1) { Appointment.count }
  
      should_assign_to(:service) { @haircut }
      should_not_assign_to(:duration)
      should_not_assign_to(:provider) # provider should be empty
      should_assign_to(:customer) { @customer }
      should_assign_to(:mark_as) { "wait" }
      should_assign_to(:appointment)
  
      should_respond_with :redirect
      should_redirect_to("appointment path") { "/appointments/#{assigns(:appointment).id}" }
    end
  end
  
end
