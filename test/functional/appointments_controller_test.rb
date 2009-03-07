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
  
  
end
