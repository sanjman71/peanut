require 'test/test_helper'
require 'test/factories'

class RecurrenceTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :company_id
  should_validate_presence_of   :service_id
  should_validate_presence_of   :provider_id
  should_validate_presence_of   :provider_type
  should_validate_presence_of   :start_at
  should_validate_presence_of   :end_at
  should_validate_presence_of   :duration
  should_allow_values_for       :mark_as, "free", "work", "wait"

  should_belong_to              :company
  should_belong_to              :service
  should_belong_to              :provider
  should_belong_to              :customer
  should_belong_to              :location
  should_have_one               :invoice
  
  def setup
    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @anywhere       = Location.anywhere
  end
  
  context "create recurring free appointment" do
    setup do
      @free_service   = @company.free_service
      @johnny         = Factory(:user, :name => "Johnny", :companies => [@company])
      @start_at_utc   = Time.now.utc.beginning_of_day
      @end_at_utc     = @start_at_utc + 2.hours
      @end_recurrence = @start_at_utc + 1.month
      @end_instances  = @start_at_utc + 2.weeks
      @rrule          = "FREQ=WEEKLY;BYDAY=TU,TH"
      @recurrence     = Recurrence.create(:company => @company, :provider => @johnny, :service => @free_service,
                              :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => "free", :rrule => @rrule)
      @recurrence.create_instances(@company, @start_at_utc, @end_instances)
      @appointments = @recurrence.appointments
    end

    should_change "Appointment.count", :by => 4
    
    should "have duration of 2 hours" do
      @appointments.each do |appt|
        assert_equal 120, appt.duration
        assert_equal 0, appt.start_at.utc.hour
        assert_equal 2, appt.end_at.utc.hour
      end
    end

    context "then delete the recurrence" do
       setup do
         @recurrence.delete
       end
       
       should_change "Appointment.count", :by => -4
       
    end
    
    context "then change the recurrence" do
      setup do
        @recurrence.rrule = "FREQ=WEEKLY;BYDAY=MO,WE,FR"
      end
      
      should_change "Appointment.count", :by => 0
      
      should "have duration of 2 hours" do
        @appointments.each do |appt|
          assert_equal 120, appt.duration
          assert_equal 0, appt.start_at.utc.hour
          assert_equal 2, appt.end_at.utc.hour
        end
      end
      
    end

  end
  
end
