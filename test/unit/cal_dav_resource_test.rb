require 'test/test_helper'
require 'test/factories'

class CalDavResourceTest < ActiveSupport::TestCase

  def setup
    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @anywhere       = Location.anywhere
  end

  context "create free time" do
    setup do
      # create free time from 10 am to 12 pm
      @free_service     = @company.free_service
      @johnny           = Factory(:user, :name => "Johnny")
      @company.providers.push(@johnny)
      @today            = Time.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range       = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt        = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :time_range => @time_range)
      @cal_dav_resource = CalDavResource.new(@company.appointments, @company)      
    end

    should_change("Appointment.count", :by => 1) { Appointment.count }

    should "give icalendar" do
      assert_not_nil @cal_dav_resource.data
    end
    
  end    

end
