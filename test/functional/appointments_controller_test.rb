require 'test/test_helper'
require 'test/factories'

class AppointmentsControllerTest < ActionController::TestCase

  # schedule a waitlist appointment for a specific schedulable, with a date range
  should_route :get, 'book/wait/users/1/services/5/20090101..20090201',
               :controller => 'appointments', :action => 'new', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 5, 
               :start_date => '20090101', :end_date => '20090201', :mark_as => 'wait'
  should_route :post, 'book/wait/users/1/services/5/20090101..20090201',
               :controller => 'appointments', :action => 'create', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 5, 
               :start_date => '20090101', :end_date => '20090201', :mark_as => 'wait'
  
  # schedule a work apppointment for a specific schedulable, service and duration
  should_route :get, 'book/work/users/3/services/3/60/20090303T113000',
               :controller => 'appointments', :action => 'new', :schedulable_type => 'users', :schedulable_id => 3, :service_id => 3, 
               :duration => 60, :start_at => '20090303T113000', :mark_as => 'work'
  should_route :post, 'book/work/users/3/services/3/60/20090303T113000',
               :controller => 'appointments', :action => 'create', :schedulable_type => 'users', :schedulable_id => 3, :service_id => 3, 
               :duration => 60, :start_at => '20090303T113000', :mark_as => 'work'
        
  def setup
    @controller   = AppointmentsController.new
    # create a valid company
    @johnny       = Factory(:user, :name => "Johnny")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @johnny, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription, :users => [@johnny])
    # create a work service, and assign johnny as a service provider
    @haircut      = Factory(:work_service, :duration => 30, :name => "Haircut", :companies => [@company], :users => [@johnny], :price => 1.00)
    # get company free service
    @free_service = @company.free_service
    # create a customer
    @customer     = Factory(:user, :name => "Customer")
    # stub current company and location methods
    @controller.stubs(:current_company).returns(@company)
    @controller.stubs(:current_location).returns(Location.anywhere)
  end

  context "book work appointment for a single date with free time, without being logged in" do
    setup do
      # create free time from 9 am to 11 am local time
      @today          = Time.now.utc.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
      @appt_datetime  = @time_range.start_at.to_s(:appt_schedule)

      # book a haircut with johnny during free time
      get :new, :schedulable => 'users', :id => @johnny.id, :service_id => @haircut.id, :start_at => @appt_datetime
    end
    
    should_respond_with :redirect
    should_redirect_to "login_path"
  end
  
  context "create free appointment for multiple dates" do
    setup do
      post :create,
           {:dates => ["20090201", "20090203"], :start_at => "0900", :end_at => "1100", :schedulable_type => "users", :schedulable_id => "#{@johnny.id}",
            :service_id => @free_service.id, :mark_as => 'free'}
    end
    
    should_change "Appointment.count", :by => 2
    
    should_respond_with :redirect
    should "redirect to user calendar path" do
      assert_redirected_to("http://www.test.host/users/#{@johnny.id}/calendar")
    end

    should_assign_to :service, :equals => "@free_service"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :start_at, :equals => '"0900"'
    should_assign_to :end_at, :equals => '"1100"'
    should_assign_to :mark_as, :equals => '"free"'
  end
  
  context "create free appointment for a single date" do
    setup do
      post :create,
           {:dates => "20090201", :start_at => "0900", :end_at => "1100", :schedulable_type => "users", :schedulable_id => "#{@johnny.id}", 
            :service_id => @free_service.id, :mark_as => 'free'}
    end
  
    should_change "Appointment.count", :by => 1
    
    should_respond_with :redirect
    should "redirect to user calendar path" do
      assert_redirected_to("http://www.test.host/users/#{@johnny.id}/calendar")
    end
    
    should_assign_to :service, :equals => "@free_service"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :start_at, :equals => '"0900"'
    should_assign_to :end_at, :equals => '"1100"'
    should_assign_to :mark_as, :equals => '"free"'
  end
  
  context "create work appointment for a single date that has no free time" do
    setup do
      post :create,
           {:dates => "20090201", :start_at => "0900", :end_at => "1100", :schedulable_type => "users", :schedulable_id => "#{@johnny.id}",
            :service_id => @haircut.id, :customer_id => @customer.id, :mark_as => 'work'}
    end
  
    should_not_change "Appointment.count"
  
    should_respond_with :redirect
    should "redirect to user calendar path" do
      assert_redirected_to("http://www.test.host/users/#{@johnny.id}/calendar")
    end

    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :start_at, :equals => '"0900"'
    should_assign_to :end_at, :equals => '"1100"'
    should_assign_to :mark_as, :equals => '"work"'
  end

  context "create work appointment for a single date with free time, replacing free time" do
    setup do
      # create free time from 9 am to 11 am local time
      @today          = Time.now.utc.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1100")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
      
      # create work appointment, today from 9 am to 11 am
      post :create,
           {:dates => @today, :start_at => "0900", :end_at => "1100", :schedulable_type => "users", :schedulable_id => "#{@johnny.id}",
            :service_id => @haircut.id, :duration => 120, :customer_id => @customer.id, :mark_as => 'work'}
    end
    
    # free appointment should be replaced with work appointment
    should_change "Appointment.count", :by => 1

    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
    should_assign_to :start_at, :equals => '"0900"'
    should_assign_to :end_at, :equals => '"1100"'
    should_assign_to :duration, :equals => '120'
    should_assign_to :mark_as, :equals => '"work"'

    should "have appointment duration of 120 minutes" do
      assert_equal 120, assigns(:appointment).duration
      assert_equal 9, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 11, assigns(:appointment).end_at.hour
      assert_equal 0, assigns(:appointment).end_at.min
    end
  end

  context "create work appointment for a single date with free time, splitting free time" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.now.utc.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
      
      # create work appointment, today from 10 am to 10:30 am local time
      post :create,
           {:dates => @today, :start_at => "1000", :end_at => "1030", :schedulable_type => "users", :schedulable_id => "#{@johnny.id}",
            :service_id => @haircut.id, :duration => 30, :customer_id => @customer.id, :mark_as => 'work'}
    end
    
    # free appointment should be split into work appointment and 2 free appointments, so we should have 3 appointments total
    should_change "Appointment.count", :by => 3
  
    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
    should_assign_to :start_at, :equals => '"1000"'
    should_assign_to :end_at, :equals => '"1030"'
    should_assign_to :duration, :equals => '30'
    should_assign_to :mark_as, :equals => '"work"'
    
    should "have appointment duration of 30 minutes" do
      assert_equal 30, assigns(:appointment).duration
      assert_equal 10, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 10, assigns(:appointment).end_at.hour
      assert_equal 30, assigns(:appointment).end_at.min
    end
  end

  context "create work appointment for a single date with free time, using a custom duration" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.now.utc.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
      
      # create work appointment, today from 10 am to 12 pm local time
      post :create,
           {:dates => @today, :start_at => "1000", :end_at => "1200", :schedulable_type => "users", :schedulable_id => "#{@johnny.id}",
            :service_id => @haircut.id, :duration => 120, :customer_id => @customer.id, :mark_as => 'work'}
    end

    # free appointment should be replaced with 1 work and 2 free appointments
    should_change "Appointment.count", :by => 3

    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
    should_assign_to :start_at, :equals => '"1000"'
    should_assign_to :end_at, :equals => '"1200"'
    should_assign_to :duration, :equals => '120'
    should_assign_to :mark_as, :equals => '"work"'

    should "have appointment duration of 120 minutes" do
      assert_equal 120, assigns(:appointment).duration
      assert_equal 10, assigns(:appointment).start_at.hour
      assert_equal 0, assigns(:appointment).start_at.min
      assert_equal 12, assigns(:appointment).end_at.hour
      assert_equal 0, assigns(:appointment).end_at.min
    end
  end
  
  context "request a waitlist appointment for a date range" do
    setup do
      # stub the current user and logged_in? state
      @controller.stubs(:logged_in?).returns(true)
      @controller.stubs(:current_user).returns(@customer)
      
      # request a waitlist appointment
      get :new,
          {:start_date => "20090201", :end_date => "20090208", :time => 'anytime', :schedulable_type => @johnny.tableize, :schedulable_id => @johnny.id,
           :service_id => @haircut.id, :mark_as => 'wait'}
    end

    should_respond_with :success
    should_render_template 'appointments/new.html.haml'

    should_not_change "Appointment.count"

    should_assign_to :daterange
    should_assign_to :appointment
    
    should "be a valid appointment" do
      assert assigns(:appointment).valid?
    end
    
    should "have a waitlist start date of 20090201 and end date of 20090208" do
      assert_equal "20090201", assigns(:appointment).start_at.to_s(:appt_schedule_day)
      assert_equal "20090208", assigns(:appointment).end_at.to_s(:appt_schedule_day)
    end
  end
  
  context "create waitlist appointment" do
    setup do
      # create waitlist appointment
      post :create,
           {:dates => 'Feb 01 2009 - Feb 08 2009', :start_at => "20090201", :end_at => "20090208", :schedulable_type => @johnny.tableize, :schedulable_id => @johnny.id,
            :service_id => @haircut.id, :customer_id => @customer.id, :mark_as => 'wait'}
    end

    should_change "Appointment.count", :by => 1
    
    should_assign_to :service, :equals => "@haircut"
    should_not_assign_to :duration
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
    should_assign_to :mark_as, :equals => '"wait"'
    should_assign_to :redirect_path, :equal => '"foo"'
    
    should_respond_with :redirect
    should "redirect to appointment confirmation path" do
      assert_redirected_to "appointments/#{assigns(:appointment).id}/confirmation"
    end
  end
end
