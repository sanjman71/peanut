require 'test/test_helper'
require 'test/factories'

class AppointmentsControllerTest < ActionController::TestCase

  # show appointment schedule for a specific schedulable
  should_route :get, 'users/1/appointments',  :controller => 'appointments', :action => 'index', :schedulable => 'users', :id => 1
  
  # search appointments for a specific schedulable
  should_route :post, 'schedulables/1/appointments/search', 
               :controller => 'appointments', :action => 'search', :schedulable => 'schedulables', :id => 1
  
  # create/schedule a waitlist appointment for a specific schedulable
  should_route :post, 'waitlist/users/1/services/5/this-week/morning', 
               :controller => 'appointments', :action => 'new', :schedulable => 'users', :id => 1, :service_id => 5, :when => 'this-week', :time => 'morning'
  
  # book a new apppointment for a specific schedulable
  should_route :get, 'book/users/3/services/3/20090303T113000',
               :controller => 'appointments', :action => 'new', :schedulable => 'users', :id => 3, :service_id => 3, :start_at => '20090303T113000'
  should_route :post, 'book/users/3/services/3/20090303T113000',
               :controller => 'appointments', :action => 'create', :schedulable => 'users', :id => 3, :service_id => 3, :start_at => '20090303T113000'
        
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
    
    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_not_assign_to :customer
    should_redirect_to "login_path"
  end
  
  context "create free appointment for multiple dates" do
    setup do
      @start_at = "0900"
      @end_at   = "1100"
      post :create,
           {:dates => ["20090201", "20090203"], :start_at => @start_at, :end_at => @end_at, :schedulable => "users/#{@johnny.id}", :service_id => @free_service.id}
    end
    
    should_change "Appointment.count", :by => 2
    
    should_respond_with :success
    should_render_template 'appointments/create.js.rjs'
    should_assign_to :service, :equals => "@free_service"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :start_at, :equals => "@start_at"
    should_assign_to :end_at, :equals => "@end_at"
  end
  
  context "create free appointment for a single date" do
    setup do
      post :create,
           {:dates => "20090201", :start_at => "0900", :end_at => "1100", :schedulable => "users/#{@johnny.id}", :service_id => @free_service.id}
    end
  
    should_change "Appointment.count", :by => 1
    
    should_respond_with :success
    should_render_template 'appointments/create.js.rjs'
    should_assign_to :service, :equals => "@free_service"
    should_assign_to :schedulable, :equals => "@johnny"
  end
  
  context "create work appointment for a single date that has no free time" do
    setup do
      post :create,
           {:dates => "20090201", :start_at => "0900", :end_at => "1100", :schedulable => "users/#{@johnny.id}", :service_id => @haircut.id,
            :customer_id => @customer.id}
    end
  
    should_not_change "Appointment.count"
  
    should_respond_with :success
    should_render_template 'appointments/create.js.rjs'
    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
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
            :customer_id => @customer.id}
    end
    
    # free appointment should be replaced with work appointment
    should_change "Appointment.count", :by => 1

    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
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
            :customer_id => @customer.id}
    end
    
    # free appointment should be split into work appointment and 2 free appointments, so we should have 3 appointments total
    should_change "Appointment.count", :by => 3

    should_assign_to :service, :equals => "@haircut"
    should_assign_to :schedulable, :equals => "@johnny"
    should_assign_to :customer, :equals => "@customer"
  end
  
end
