require 'test/test_helper'
require 'test/factories'

class RecurrenceTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :company_id
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
  
  DAYS_OF_WEEK = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU']
  
  def setup
    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @anywhere       = Location.anywhere
    @customer       = Factory(:user, :name => "Customer", :companies => [@company])
    @provider       = Factory(:user, :name => "Provider", :companies => [@company])
    @work_service   = Factory(:work_service, :name => "Work service", :companies => [@company], :price => 1.00)
    @free_service   = @company.free_service
  end
  
  context "create one invalid recurring free appointment (private, no service)" do
    setup do
      @start_at_utc   = Time.now.utc.beginning_of_day
      @end_at_utc     = @start_at_utc + 2.hours
      @end_recurrence = @start_at_utc + 8.weeks
      # Recur 2 and 4 days from now
      @recur_days     = "#{DAYS_OF_WEEK[(Time.now + 2.days).wday]},#{DAYS_OF_WEEK[(Time.now + 4.days).wday]}"
      @rrule          = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Recurrence.new(:company => @company, :customer => @customer, :provider => @provider,
                                        :start_at => @start_at_utc, :end_at => @end_at_utc, :public => false,
                                        :mark_as => "free", :rrule => @rrule, :description => "This is the recurrence description")
    end
    
    should "not be valid" do
      assert_false @recurrence.valid?
    end

  end
    
  context "create one invalid recurring free appointment (private, no provider)" do
    setup do
      @start_at_utc   = Time.now.utc.beginning_of_day
      @end_at_utc     = @start_at_utc + 2.hours
      @end_recurrence = @start_at_utc + 8.weeks
      # Recur 2 and 4 days from now
      @recur_days     = "#{DAYS_OF_WEEK[(Time.now + 2.days).wday]},#{DAYS_OF_WEEK[(Time.now + 4.days).wday]}"
      @rrule          = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Recurrence.new(:company => @company, :customer => @customer, :service => @free_service,
                                        :start_at => @start_at_utc, :end_at => @end_at_utc, :public => false,
                                        :mark_as => "free", :rrule => @rrule, :description => "This is the recurrence description")
    end
    
    should "not be valid" do
      assert_false @recurrence.valid?
    end

  end
    
  context "create one valid recurring free private appointment" do
    setup do
      @start_at_utc   = Time.now.utc.beginning_of_day
      @end_at_utc     = @start_at_utc + 2.hours
      @end_recurrence = @start_at_utc + 8.weeks
      @recur_days     = "#{DAYS_OF_WEEK[(Time.now + 2.days).wday]},#{DAYS_OF_WEEK[(Time.now + 4.days).wday]}"
      @rrule          = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Recurrence.create(:company => @company, :customer => @customer, :provider => @provider, :service => @free_service,
                                          :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => "free",
                                          :rrule => @rrule, :description => "This is the recurrence description")
      @recurrence.expand_instances(Time.now, Time.now + 4.weeks)
    end

    should_change "Appointment.count", :by => 8
    
    should_not_change "Appointment.public.count"

    should "have duration of 2 hours" do
      @recurrence.appointments.each do |a|
        assert_equal 120, a.duration
        assert_equal 0, a.start_at.utc.hour
        assert_equal 2, a.end_at.utc.hour
      end
    end
    
    should "have same attributes as recurrence" do
      @recurrence.appointments.each do |a|
        assert_equal @recurrence.company_id, a.company_id
        assert_equal @recurrence.service_id, a.service_id
        assert_equal @recurrence.location_id, a.location_id
        assert_equal @recurrence.provider_id, a.provider_id
        assert_equal @recurrence.customer_id, a.customer_id
        assert_equal @recurrence.mark_as, a.mark_as
        assert_equal @recurrence.confirmation_code, a.confirmation_code
        assert_equal @recurrence.uid, a.uid
        assert_equal @recurrence.description, a.description
        assert_equal @recurrence.public, a.public
        assert_equal @recurrence.name, a.name
        assert_equal @recurrence.popularity, a.popularity
        assert_equal @recurrence.url, a.url
        assert_equal @recurrence.source_type, a.source_type
        assert_equal @recurrence.source_id, a.source_id
      end
    end
    

    should "have a valid uid" do
      assert !(@recurrence.uid.blank?)
      assert_match Regexp.new("[0-9]*-r-[0-9]*@walnutindustries.com"), @recurrence.uid
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

    context "then create a second recurrence" do
      setup do
        @start_at_utc   = Time.now.utc.beginning_of_day
        @end_at_utc     = @start_at_utc + 30.minutes
        @end_recurrence = @start_at_utc + 8.weeks
        @recur_days     = "#{DAYS_OF_WEEK[(Time.now + 1.day).wday]},#{DAYS_OF_WEEK[(Time.now + 5.days).wday]}"
        @rrule          = "FREQ=WEEKLY;INTERVAL=2;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
        @recurrence2    = Recurrence.create(:company => @company, :customer => @customer,  :provider => @provider, :service => @free_service,
                                            :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => "free",
                                            :rrule => @rrule, :description => "This is the 2nd recurrence description")
        appointments    = @recurrence2.expand_instances(Time.now, Time.now + 4.weeks)
      end

      should_change "Appointment.count", :by => 4

      should "have duration of 30 minutes" do
        @recurrence2.appointments.each do |a|
          assert_equal 30, a.duration
          assert_equal 0, a.start_at.utc.hour
          assert_equal 0, a.end_at.utc.hour
          assert_equal 30, a.end_at.min
        end
      end
      
    end
    
    context "delete the second recurrence" do
      setup do
        setup do
          @recurrence2.destroy
        end

        should_change "Appointment.count", :by => 4
      end
      
    end

    context "then search for available time" do
      
    end
    
    
    context "then schedule an overlapping available appointment" do
      
    end
    
    
  end
  
  context "create an available appointment" do
    
    context "and then create a recurring available appointment overlapping the existing available appointment" do
      
    end

  end
  
  context "create a recurring free public appointment ending in 2 weeks" do
    setup do
      @start_at_utc   = Time.now.utc.beginning_of_day
      @end_at_utc     = @start_at_utc + 2.hours
      @end_recurrence = @start_at_utc + 2.weeks
      @recur_days     = "#{DAYS_OF_WEEK[(Time.now + 3.days).wday]}"
      @rrule          = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Recurrence.create(:company => @company, :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => "free",
                                          :rrule => @rrule, :name => "Happy Hour!", 
                                          :description => "$2 beers, $3 well drinks", :public => true)
      @recurrence.expand_instances(Time.now, Time.now + 4.weeks)
    end
    
    should_change "Appointment.count", :by => 2
    
    should_change "Appointment.public.count", :by => 2

  end
  
  context "create a recurring free public appointment with no end instantiating 3 instances" do
    setup do
      @start_at_utc   = Time.now.utc.beginning_of_day
      @end_at_utc     = @start_at_utc + 2.hours
      @recur_days     = "#{DAYS_OF_WEEK[(Time.now + 3.days).wday]}"
      @rrule          = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
      @recurrence     = Recurrence.create(:company => @company, :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => "free",
                                          :rrule => @rrule, :name => "Happy Hour!", 
                                          :description => "$2 beers, $3 well drinks", :public => true)
      @appointments   = @recurrence.expand_instances(Time.now, Time.now + 4.weeks, 3)
    end
    
    should_change "Appointment.count", :by => 3
    
    should_change "Appointment.public.count", :by => 3
    
    should "have 3 appointments returned from expand_instances" do
      assert_equal  3, @appointments.size
    end

  end
  
end
