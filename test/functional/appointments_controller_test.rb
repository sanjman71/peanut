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

    @controller   = AppointmentsController.new
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
    @company.user_providers.push(@johnny)
    @johnny.email_addresses.create(:address => 'johnny@walnutcalendar.com')
    @mary = Factory(:user, :name => "Mary")
    # @mary.grant_role('user manager', @mary)
    @company.user_providers.push(@mary)
    @company.reload
    # create a work service, and assign johnny as a service provider
    @haircut      = Factory.build(:work_service, :duration => 30.minutes, :name => "Haircut", :price => 1.00)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    @haircut.user_providers.push(@mary)
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
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, :time_range => @time_range)
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
  
      should "show rpx login" do
        assert_select 'div#rpx_login', true
      end
  
      should "show (hidden) peanut login" do
        assert_select 'div.hide#peanut_login', true
      end
  
      should "not show reminder options" do
        assert_select "input#reminder_on", 0
        assert_select "input#reminder_off", 0
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
  
        should "not show reminder options" do
          assert_select "input#reminder_on", 0
          assert_select "input#reminder_off", 0
        end
  
        should_respond_with :success
        should_render_template 'appointments/new.html.haml'
      end
    end
  
    context "create work appointment as customer" do
      setup do
        # stub current user
        @controller.stubs(:current_user).returns(@customer)
        post :create_work,
             :provider_type => 'users', :provider_id => @johnny.id, :service_id => @haircut.id, :start_at => @appt_datetime,
             :duration => @haircut.duration, :customer_id => @customer.id
      end
  
      should_respond_with :redirect
      should_redirect_to ("history_index_path") { history_index_path }
  
      context "delete free appointment containing active work appointment" do
        setup do
          delete :destroy, :id => @free_appt.id
        end
  
        should_not_change("Appointment.count") { Appointment.count }
        should "not delete free appointment" do
          assert Appointment.find(@free_appt.id)
        end
      end
    end
  end
  
  context "create free appointment" do
    context "without privilege 'update calendars'" do
      setup do
        @controller.stubs(:current_user).returns(@customer)
        post :create_free,
             {:date => "20090201", :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}"}
      end
  
      should_not_change("Appointment.count") { Appointment.count }
      should_respond_with :redirect
      should_redirect_to("unauthorized_path") { unauthorized_path }
    end
    
    context "for a single date" do
      setup do
        # have johnny create free appointments on his calendar
        @controller.stubs(:current_user).returns(@johnny)
        post :create_free,
             {:date => "20090201", :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}"}
      end
  
      should_change("Appointment.count", :by => 1) { Appointment.count }
  
      should_assign_to(:service) { @free_service }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at)  { "0900" }
      should_assign_to(:end_at) { "1100" }
      should_assign_to(:mark_as) { "free" }
  
      should_respond_with :redirect
      should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
    end
  
     context "for a block of dates" do
       setup do
         # have johnny create free appointments on his calendar
         @controller.stubs(:current_user).returns(@johnny)
         post :create_block,
              {:dates => ["20090201", "20090203"], :start_at => "0900", :end_at => "1100", :provider_type => "users", :provider_id => "#{@johnny.id}"}
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
  
      should_respond_with :redirect
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
    
      should_respond_with :success
      should_render_template 'appointments/edit_block.html.haml'
  
      should_assign_to(:provider) { @johnny }
      should_assign_to :providers, :class => Array
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to :daterange, :class => DateRange
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
  
      should_respond_with :redirect
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
    
      should_respond_with :success
      should_render_template 'appointments/edit_weekly.html.haml'
  
      should_assign_to(:provider) { @johnny }
      should_assign_to :providers, :class => Array
      should_assign_to :calendar_markings, :class => Hash
      should_assign_to :daterange, :class => DateRange
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
  
      should_respond_with :redirect
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
  
      should_respond_with :redirect
      should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }
    end
  end
  
  context "create work appointment for a single date that has no free time" do
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
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id, :customer_id => @customer.id, :force_add => 1}
      end
    
      # Should fail to add the appointment
      should_not_change("Appointment.count") { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }
    
      should_respond_with :redirect
      should_redirect_to("user history page" ) { "/history" }
      
    end
    
    context "as a provider requesting force add in their own calendar" do
      
      setup do
        @controller.stubs(:current_user).returns(@johnny)
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
             :service_id => @haircut.id, :customer_id => @customer.id, :force_add => 1}
      end
    
      # Should succeed
      should_change("Appointment.count", :by => 1) { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }
      
      should_respond_with :redirect
      should_redirect_to("provider's calendar path" ) { "/users/#{@johnny.id}/calendar" }
      
    end
    
    context "as a provider requesting force add in another provider's calendar" do
      
      setup do
        @controller.stubs(:current_user).returns(@mary)
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
             :service_id => @haircut.id, :customer_id => @customer.id, :force_add => 1}
      end
    
      should_not_change("Appointment.count") { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }
    
      should_respond_with :redirect
      should_redirect_to("provider's calendar path" ) { "/users/#{@johnny.id}/calendar" }
      
    end
    
    context "as an owner without requesting to force add" do
      setup do
        # create work appointment as customer
        @controller.stubs(:current_user).returns(@owner)
        # create work appointment, today from 10 am to 12 pm local time
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id, :customer_id => @customer.id}
      end
    
      # Should fail to add the appointment
      should_not_change("Appointment.count") { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }
    
      should_respond_with :redirect
      should_redirect_to("provider's calendar path" ) { "/users/#{@johnny.id}/calendar" }
      
    end
    
    context "as an owner requesting not to force add" do
      setup do
        # create work appointment as customer
        @controller.stubs(:current_user).returns(@owner)
        # create work appointment, today from 10 am to 12 pm local time
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id, :customer_id => @customer.id, :force_add => 0}
      end
    
      # Should fail to add the appointment
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
        post :create_work,
             {:start_at => @start_at, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id, :customer_id => @customer.id, :force_add => 1}
      end
    
      # Should succeed in adding the appointment
      should_change("Appointment.count", :by => 1) { Appointment.count }
    
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:start_at) { @start_at }
      should_assign_to(:mark_as) { "work" }
    
      should_respond_with :redirect
      should_redirect_to("provider's calendar path" ) { "/users/#{@johnny.id}/calendar" }
      
    end

  end
  
  context "create work appointment for a single date with free time, replacing free time" do
    setup do
      # create free time from 9 am to 11 am local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, :time_range => @time_range)
  
      @start_at       = "#{@today}T0900"
      @duration       = 2.hours
  
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)
  
      # create work appointment, today from 9 am to 11 am
      post :create_work,
           {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :customer_id => @customer.id}
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
      
    should_respond_with :redirect
    should_redirect_to("history path") { "/history" }
  end
  
  context "create work appointment for a single date with free time, splitting free time" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, :time_range => @time_range)
  
      @start_at       = "#{@today}T1000"
      @duration       = 30.minutes
  
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)
  
      # create work appointment, today from 10 am to 10:30 am local time
      post :create_work,
           {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :customer_id => @customer.id}
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
  
    should_respond_with :redirect
    should_redirect_to("history path") { "/history" }
  end
  
  context "create work appointment for a single date with free time, using a custom duration" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, :time_range => @time_range)
  
      @start_at       = "#{@today}T1000"
      @duration       = 120.minutes
  
      # create work appointment as customer
      @controller.stubs(:current_user).returns(@customer)
  
      # create work appointment, today from 10 am to 12 pm local time
      post :create_work,
           {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
            :service_id => @haircut.id, :customer_id => @customer.id}
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
  
    should_respond_with :redirect
    should_redirect_to("history path") { "/history" }
  end
  
  context "create work appointment" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.zone.now.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, :time_range => @time_range)
  
      @start_at       = "#{@today}T1000"
      @duration       = 120.minutes
    end
    
    context "with a new customer signup" do
      setup do
        # create work appointment as anonymous user
        @controller.stubs(:current_user).returns(nil)
        @controller.stubs(:logged_in?).returns(false)
  
        # create work appointment, today from 10 am to 12 pm local time
        post :create_work,
             {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
              :service_id => @haircut.id,
              :customer => {:name => "Sanjay", :email => "sanjay@walnut.com", :password => 'sanjay', :password_confirmation => 'sanjay'}}
        @free_appt.reload
      end
  
      # create new customer
      should_change("User.count", :by => 1) { User.count}
  
      # should add work appointment
      should_change("Appointment.count", :by => 1) { Appointment.count }
  
      should "have two capacity slots" do
        assert_equal 2, @free_appt.capacity_slots.size
      end
  
      should_assign_to(:service) { @haircut }
      should_assign_to(:provider) { @johnny }
      should_assign_to(:customer) { User.with_email("sanjay@walnut.com").first }
      should_assign_to(:start_at) { @start_at }
      should_not_assign_to(:end_at)
      should_assign_to(:duration)  { 120.minutes }
      should_assign_to(:mark_as) { "work" }
      should_assign_to(:appointment)
      
      should "create user in active state" do
        user = User.with_email("sanjay@walnut.com").first
        assert_equal 'active', user.state
      end
      
      should "create user with specified password" do
        user = User.authenticate('sanjay@walnut.com', 'sanjay')
        assert_equal assigns(:customer), user
      end
      
      should "set the flash for the created work appointment" do
        assert_match /Your Haircut appointment has been confirmed/, flash[:notice]
      end
      
      should "set the flash for the created appointment and created user account" do
        assert_match /Your user account has been created/, flash[:notice]
      end
  
      # should send appt confirmation and account created messages
      should_change("delayed job count", :by => 2) { Delayed::Job.count }
  
      should_respond_with :redirect
      should_redirect_to("openings path") { "/openings" }
    end
  
    context "with appointment confirmations" do
      context "to nobody" do
        setup do
          @company.preferences[:work_appointment_confirmations] = [:nobody]
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
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
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
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
          @company.preferences[:work_appointment_confirmations] = [:provider]
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
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
          @company.preferences[:work_appointment_confirmations] = [:managers]
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
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
          @company.preferences[:work_appointment_confirmations] = [:customer, :managers]
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
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
    end
  
    context "with appointment reminders" do
      context "turned on" do
        setup do
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id, :preferences_reminder => '1'}
        end
  
        should "set appointment reminders on" do
          assert_equal 1, assigns(:appointment).preferences[:reminder].to_i
        end
      end
  
      context "turned off" do
        setup do
          # create work appointment as company manager
          @controller.stubs(:current_user).returns(@owner)
          # create work appointment, today from 10 am to 12 pm local time
          post :create_work,
               {:start_at => @start_at, :duration => @duration, :provider_type => "users", :provider_id => "#{@johnny.id}",
                :service_id => @haircut.id, :customer_id => @customer.id, :preferences_reminder => '0'}
        end
  
        should "set appointment reminders off" do
          assert_equal 0, assigns(:appointment).preferences[:reminder].to_i
        end
      end
    end
   
  end
  
end
