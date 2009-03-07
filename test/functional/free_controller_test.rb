require 'test/test_helper'
require 'test/factories'

class FreeControllerTest < ActionController::TestCase

  # add free time for a specific resource
  should_route :get, 'users/1/free/block', :controller => "free", :action => 'new', :schedulable => "users", :id => "1", :style => "block"
  
  def setup
    @controller   = FreeController.new
    # create a valid company
    @johnny       = Factory(:user, :name => "Johnny")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @johnny, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription, :users => [@johnny])
    # create a work service
    @haircut      = Factory(:work_service, :name => "Haircut", :companies => [@company], :price => 1.00)
    # get company free service
    @free_service = @company.free_service
    # create customer
    @customer     = Factory(:user, :name => "Customer")
    # stub current company and location methods
    @controller.stubs(:current_company).returns(@company)
    @controller.stubs(:current_location).returns(Location.anywhere)
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
    should_render_template 'free/create.js.rjs'
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
    should_render_template 'free/create.js.rjs'
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
    should_render_template 'free/create.js.rjs'
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
