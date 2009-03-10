require 'test/test_helper'
require 'test/factories'

class AppointmentsControllerTest < ActionController::TestCase

  # show appointment schedule for a specific schedulable
  should_route :get, 'users/1/appointments',  :controller => 'appointments', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1
  
  # search appointments for a specific schedulable
  should_route :post, 'schedulables/1/appointments/search', 
               :controller => 'appointments', :action => 'search', :schedulable_type => 'schedulables', :schedulable_id => 1
  
  # schedule a waitlist appointment for a specific schedulable
  should_route :get, 'waitlist/users/1/services/5/this-week/morning',
               :controller => 'appointments', :action => 'new', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 5, 
               :when => 'this-week', :time => 'morning', :mark_as => 'wait'
  should_route :post, 'waitlist/users/1/services/5/this-week/morning',
               :controller => 'appointments', :action => 'create', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 5, 
               :when => 'this-week', :time => 'morning', :mark_as => 'wait'
  
  # schedule a work apppointment for a specific schedulable and service with a specific duration
  should_route :get, 'book/users/3/services/3/duration/60/20090303T113000',
               :controller => 'appointments', :action => 'new', :schedulable_type => 'users', :schedulable_id => 3, :service_id => 3, 
               :duration => 60, :start_at => '20090303T113000', :mark_as => 'work'
  should_route :post, 'book/users/3/services/3/duration/60/20090303T113000',
               :controller => 'appointments', :action => 'create', :schedulable_type => 'users', :schedulable_id => 3, :service_id => 3, 
               :duration => 60, :start_at => '20090303T113000', :mark_as => 'work'
        
  def setup
    @controller   = AppointmentsController.new
    # create a valid company
    @johnny       = Factory(:user, :name => "Johnny")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @johnny, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription, :users => [@johnny])
    # create a work service
    @haircut      = Factory(:work_service, :name => "Haircut", :companies => [@company], :price => 1.00)
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
           {:dates => ["20090201", "20090203"], :start_at => "0900", :end_at => "1100", :schedulable => "users/#{@johnny.id}",
            :service_id => @free_service.id, :mark_as => 'free'}
    end
    
    should_change "Appointment.count", :by => 2
    
    should_respond_with :redirect
    should "redirect to users/:id/appointments path" do
      assert_redirected_to("http://www.test.host/users/#{@johnny.id}/appointments")
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
           {:dates => "20090201", :start_at => "0900", :end_at => "1100", :schedulable => "users/#{@johnny.id}", 
            :service_id => @free_service.id, :mark_as => 'free'}
    end
  
    should_change "Appointment.count", :by => 1
    
    should_respond_with :redirect
    should "redirect to users/:id/appointments path" do
      assert_redirected_to("http://www.test.host/users/#{@johnny.id}/appointments")
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
           {:dates => "20090201", :start_at => "0900", :end_at => "1100", :schedulable => "users/#{@johnny.id}", :service_id => @haircut.id,
            :customer_id => @customer.id, :mark_as => 'work'}
    end
  
    should_not_change "Appointment.count"
  
    should_respond_with :redirect
    should "redirect to users/:id/appointments path" do
      assert_redirected_to("http://www.test.host/users/#{@johnny.id}/appointments")
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
           {:dates => @today, :start_at => "0900", :end_at => "1100", :schedulable => "users/#{@johnny.id}", :service_id => @haircut.id,
            :customer_id => @customer.id, :mark_as => 'work'}
    end
    
    # free appointment should be replaced with work appointment
    should_change "Appointment.count", :by => 1

    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
    should_assign_to :start_at, :equals => '"0900"'
    should_assign_to :end_at, :equals => '"1100"'
    should_assign_to :mark_as, :equals => '"work"'
  end

  context "create work appointment for a single date with free time, splitting free time" do
    setup do
      # create free time from 9 am to 3 pm local time
      @today          = Time.now.utc.to_s(:appt_schedule_day)
      @time_range     = TimeRange.new(:day => @today, :start_at => "0900", :end_at => "1500")
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
      
      # create work appointment, today from 10 am to 11 am local time
      post :create,
           {:dates => @today, :start_at => "1000", :end_at => "1100", :schedulable => "users/#{@johnny.id}", :service_id => @haircut.id,
            :customer_id => @customer.id, :mark_as => 'work'}
    end
    
    # free appointment should be split into work appointment and 2 free appointments, so we should have 3 appointments total
    should_change "Appointment.count", :by => 3

    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
    should_assign_to :start_at, :equals => '"1000"'
    should_assign_to :end_at, :equals => '"1100"'
    should_assign_to :mark_as, :equals => '"work"'
  end

  context "create waitlist appointment for this week" do
    setup do
      # create waitlist appointment
      post :create,
           {:dates => 'this-week', :when => "this-week", :time => 'anytime', :schedulable => "users/#{@johnny.id}", :service_id => @haircut.id,
            :customer_id => @customer.id, :mark_as => 'wait'}
    end
    
    should_change "Appointment.count", :by => 1
    
    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
    should_assign_to :when, :equals => '"this week"'
    should_assign_to :time, :equals => '"anytime"'
    should_assign_to :mark_as, :equals => '"wait"'
  end
end
