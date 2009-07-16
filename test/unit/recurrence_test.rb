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
  should_have_many              :appointments
  
  def setup
    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @anywhere       = Location.anywhere
  end
  
  context "create one recurring free appointment" do
    setup do
      @free_service   = @company.free_service
      @johnny         = Factory(:user, :name => "Johnny", :companies => [@company])
      @start_at_utc   = Time.now.utc.beginning_of_day
      @end_at_utc     = @start_at_utc + 2.hours
      @end_recurrence = @start_at_utc + 8.weeks
      @rrule          = "FREQ=WEEKLY;BYDAY=TU,TH"
      @recurrence     = Recurrence.create(:company => @company, :provider => @johnny, :service => @free_service,
                                          :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => "free",
                                          :rrule => @rrule, :description => "This is the recurrence description")
    end

    should_change "Appointment.count", :by => 8
    
    should "have duration of 2 hours" do
      @recurrence.appointments.each do |a|
        assert_equal 120, a.duration
        assert_equal 0, a.start_at.utc.hour
        assert_equal 2, a.end_at.utc.hour
      end
    end

    context "then delete the recurrence" do
       setup do
         @recurrence.destroy
       end
       
       should_change "Appointment.count", :by => -8
       
    end
    
    context "then change the recurrence description" do
      setup do
        @recurrence.description = "This is a changed recurring description"
        @recurrence.save
      end
      
      should_not_change "Appointment.count"

      should "change appointments' description" do
        @recurrence.appointments.each do |a|
          assert_equal "This is a changed recurring description", a.description
        end
      end
      
    end
    
    context "then change end time and duration of the recurrence" do
      setup do
        @recurrence.end_at = @recurrence.start_at + 3.hours
        @recurrence.duration = 3.hours / 60
        @recurrence.save
        @recurrence.reload
      end
      
      should_change "Appointment.count", :by => 0
      
      should "change appointments' end time and duration" do
        @recurrence.appointments.each do |a|
          assert_equal 180, a.duration
          assert_equal 0, a.start_at.utc.hour
          assert_equal 3, a.end_at.utc.hour
        end
      end
      
    end
    
    context "then change the recurrence rule to 3 per week" do
      setup do
        @recurrence.rrule = "FREQ=WEEKLY;BYDAY=MO,WE,FR"
        @recurrence.save
        @recurrence.reload
      end
      
      should_change "Appointment.count", :by => 4
      
      should "not change appointments' end time and duration" do
        @recurrence.appointments.each do |a|
          assert_equal 120, a.duration
          assert_equal 0, a.start_at.utc.hour
          assert_equal 2, a.end_at.utc.hour
        end
      end
      
    end

    context "then change the recurrence rule to 3 per week and change end time" do
      setup do
        @recurrence.end_at = @recurrence.start_at + 3.hours
        @recurrence.duration = 3.hours / 60
        @recurrence.rrule = "FREQ=WEEKLY;BYDAY=MO,WE,FR"
        @recurrence.save
        @recurrence.reload
      end
      
      should_change "Appointment.count", :by => 4
      
      should "change appointments' end time and duration" do
        @recurrence.appointments.each do |a|
          assert_equal 180, a.duration
          assert_equal 0, a.start_at.utc.hour
          assert_equal 3, a.end_at.utc.hour
        end
      end
      
    end

  end
  
end
