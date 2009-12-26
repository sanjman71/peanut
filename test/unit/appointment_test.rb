require 'test/test_helper'
require 'test/factories'

class AppointmentTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :company_id
  should_validate_presence_of   :start_at
  should_validate_presence_of   :end_at
  should_validate_presence_of   :duration
  should_allow_values_for       :mark_as, "free", "work"
  
  should_belong_to              :company
  should_belong_to              :service
  should_belong_to              :provider
  should_belong_to              :customer
  should_have_one               :invoice
  should_belong_to              :location
  should_have_many              :capacity_slots
  
  should_belong_to              :recur_parent
  should_have_many              :recur_instances
  
  def setup
    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @anywhere       = Location.anywhere
    @provider       = Factory(:user, :name => "Provider")
    @provider2      = Factory(:user, :name => "Provider With Capacity 2", :capacity => 2)
    @company.user_providers.push(@provider)
    @company.user_providers.push(@provider2)
    @company.reload
    @work_service   = Factory.build(:work_service, :name => "Work service", :price => 1.00)
    @work_service2  = Factory.build(:work_service, :name => "Work service Capacity 2", :price => 1.00, :capacity => 2)
    @company.services.push(@work_service)
    @company.services.push(@work_service2)
    @work_service.user_providers.push(@provider)
    @work_service2.user_providers.push(@provider2)
    @free_service   = @company.free_service
    @customer       = Factory(:user)
  end
  
  context "appointment state" do
    setup do
      # create free time from 12 midnight to 1 am
      @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @today, :start_at => "0000", :end_at => "0100"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, :time_range => @time_range)
    end
  
    should "create in confirmed state" do
      assert_equal 'confirmed', @free_appt.reload.state
    end
  
    context "then mark as completed" do
      setup do
        @free_appt.complete!
      end
  
      should "change state to completed" do
        assert_equal 'completed', @free_appt.reload.state
      end
    end
  
    context "then mark as canceled" do
      setup do
        @free_appt.cancel!
      end
  
      should "change state to canceled" do
        assert_equal 'canceled', @free_appt.reload.state
      end
    end
  
    context "then mark as noshow" do
      setup do
        @free_appt.noshow!
      end
  
      should "change state to noshow" do
        assert_equal 'noshow', @free_appt.reload.state
      end
    end
  end
  
  context "create free appointment with mismatched duration and end_at values" do
    setup do
      @start_at_utc   = Time.zone.now.beginning_of_day.utc
      @end_at_utc     = @start_at_utc + 1.hour
      @start_at_day   = @start_at_utc.to_s(:appt_schedule_day)
      @daterange      = DateRange.parse_range(@start_at_day, @start_at_day)
      @appt           = AppointmentScheduler.create_free_appointment(@company, @provider,
                                                                     :start_at => @start_at_utc, :end_at => @end_at_utc, :duration => 2.hours)
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
  
    should "have duration of 2 hours, and end_at time adjusted, and capacity 1" do
      assert_equal 2.hours, @appt.duration
      assert_equal 0, @appt.start_at.in_time_zone.hour
      assert_equal 2, @appt.end_at.in_time_zone.hour
      assert_equal 1, @appt.capacity
      assert_equal 1, @appt.capacity_slots.first.capacity
      assert_equal 1, @appt.capacity_slots.count
    end
  
    should "have a valid uid" do
      assert !(@appt.uid.blank?)
      assert_match Regexp.new("[0-9]*-[0-9]*@walnutindustries.com"), @appt.uid
    end
  end
  
  context "create free appointment and test unscheduled time" do
    setup do
      @start_at_utc   = Time.zone.now.beginning_of_day.utc
      @end_at_utc     = @start_at_utc + 1.hour
      @start_at_day   = @start_at_utc.to_s(:appt_schedule_day)
      @daterange      = DateRange.parse_range(@start_at_day, @start_at_day)
      @appt           = AppointmentScheduler.create_free_appointment(@company, @provider, :start_at => @start_at_utc, :end_at => @end_at_utc)
    end
      
    should_change("Appointment.count", :by => 1) { Appointment.count }
    
    should "should not have a customer" do
      assert_equal nil, @appt.customer
    end
    
    should "have 1 unscheduled slot today for 23 hours starting at 1 am" do
      # build mapping of unscheduled time
      @unscheduled = AppointmentScheduler.find_unscheduled_time(@company, @anywhere, @provider, @daterange)
      assert_equal [@start_at_day], @unscheduled.keys
      assert_equal 1, @unscheduled[@start_at_day].size
      assert_equal 23.hours, @unscheduled[@start_at_day].first.duration
      assert_equal 1, @unscheduled[@start_at_day].first.start_at.in_time_zone.hour
      assert_equal 0, @unscheduled[@start_at_day].first.end_at.in_time_zone.hour
    end
  
    context "then remove company" do
      setup do
        @company.destroy
      end
  
      should "have no Companies or associated models" do
        assert_equal 0, Company.count
        assert_equal 0, Appointment.count
        assert_equal 0, Subscription.count
        assert_equal 0, CompanyProvider.count
        assert_equal 0, CapacitySlot.count
      end
    end
  end
  
  context "create free appointment" do
    setup do
      # create free time from 10 am to 12 pm
      @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, :time_range => @time_range)
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
    
    context "and schedule work appointment without a customer" do
      should "raise exception" do
        assert_raise ArgumentError do
          @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @work_service.duration)
        end
      end
    end
  
    context "and schedule work appointment to test confirmation code" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @work_service.duration, @customer, @options)
        assert_valid @work_appt
      end
  
      should "have confirmation code of exactly 5 characters" do
        assert_equal 5, @work_appt.confirmation_code.size
        assert_match /([A-Z]|[0-9])+/, @work_appt.confirmation_code
      end
    end
  
    context "and schedule work appointment to test customer role" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @work_service.duration, @customer, @options)
        assert_valid @work_appt
        @customer.reload
      end
  
      should "add 'user manager' role on user to customer" do
        assert_equal ['user manager'], @customer.roles_on(@customer).collect(&:name).sort
      end
  
      should "add 'company customer' role on company to customer" do
        assert_equal ['company customer'], @customer.roles_on(@company).collect(&:name).sort
      end
    end
  
    context "and schedule work appointment with a custom service duration" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, 2.hours, @customer, @options)
        assert_valid @work_appt
      end
  
      should "have work service with duration of 120 minutes" do
        assert_equal @work_service, @work_appt.service
        assert_equal 2.hours, @work_appt.duration
        assert_equal 10, @work_appt.start_at.hour
        assert_equal 12, @work_appt.end_at.hour
      end
  
      context "then remove company" do
        setup do
          @company.destroy
        end
  
        should "have no companies or associated models" do
          assert_equal 0, Company.count
          assert_equal 0, Appointment.count
          assert_equal 0, Subscription.count
          assert_equal 0, CompanyProvider.count
          assert_equal 0, CapacitySlot.count
        end
      end
    end
    
    context "and schedule work appointment to test larger service capacity = 2" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
      end
  
      should "raise exception" do
        assert_raise AppointmentInvalid do
          @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service2, @work_service2.duration, @customer, @options)
        end
      end
    end
    
    context "and create a conflicting free appointment" do
      setup do
        # create free time from 10 am to 12 pm
        @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
        @time_range     = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      end
  
      should "raise exception" do
        assert_raise TimeslotNotEmpty do
          @free_appt2   = AppointmentScheduler.create_free_appointment(@company, @provider, :time_range => @time_range)
        end
      end
      
    end
    
  end
  
  context "create work appointment to check time overlap searching" do
    setup do
      # start at 2 pm, local time
      @start_at_local = Time.zone.now.beginning_of_day + 14.hours
      @start_at_utc   = @start_at_local.utc
    
      @appt = @company.appointments.create(:service => @work_service,
                                           :provider => @provider,
                                           :customer => @customer,
                                           :start_at => @start_at_local,
                                           :duration => @work_service.duration)

      assert_valid @appt
      @end_at_utc = @appt.end_at.utc
    end
  
    should "have time of day values based on start/end times in utc format" do
      assert_equal '', @appt.time
      assert_equal @start_at_utc.hour.hours + @start_at_utc.min.minutes, @appt.time_start_at
      assert_equal @end_at_utc.hour.hours + @end_at_utc.min.minutes, @appt.time_end_at
    end
  
    should "match afternoon and anytime time of day searches" do
      assert_equal [@appt], Appointment.time_overlap(Appointment.time_range("afternoon"))
      assert_equal [@appt], Appointment.time_overlap(Appointment.time_range("anytime"))
    end
  
    should "not match morning, evening, or invalid time of day searches" do
      assert_equal [], Appointment.time_overlap(Appointment.time_range("morning"))
      assert_equal [], Appointment.time_overlap(Appointment.time_range("evening"))
      assert_equal [], Appointment.time_overlap(Appointment.time_range("bogus"))
    end
  end

  context "create work appointment to check appointment roles and privileges" do
    setup do
      # initialize roles and privileges
      BadgesInit.roles_privileges

      # start at 2 pm, local time
      @start_at_local = Time.zone.now.beginning_of_day + 14.hours

      @appt = @company.appointments.create(:service => @work_service,
                                           :provider => @provider,
                                           :customer => @customer,
                                           :start_at => @start_at_local,
                                           :duration => @work_service.duration)

      assert_valid @appt
      @end_at_utc = @appt.end_at.utc
    end
  
    should "grant customer 'appointment manager' role on the appointment" do
      assert_equal ['appointment manager'], @customer.roles_on(@appt).collect(&:name).sort
    end
  
    should "grant provider 'appointment manager' role on the appointment" do
      assert_equal ['appointment manager'], @provider.roles_on(@appt).collect(&:name).sort
    end
  end
  
  context "build new appointment with time range attributes and am/pm times" do
    setup do
      @today = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @appt  = Appointment.new(:time_range => {:day => @today, :start_at => "1 pm", :end_at => "3 pm"})
    end
    
    should "have start time today at 1 pm local time" do
      assert_equal @today, @appt.start_at.to_s(:appt_schedule_day)
      assert_equal 13, @appt.start_at.hour
      assert_equal 0, @appt.start_at.min
    end
    
    should "have end time today at 3 pm local time" do
      assert_equal @today, @appt.end_at.to_s(:appt_schedule_day)
      assert_equal 15, @appt.end_at.hour
      assert_equal 0, @appt.end_at.min
    end
  end
  
  context "build new appointment with time range object and numeric times" do
    setup do
      @today      = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @appt       = Appointment.new(:time_range => @time_range)
    end
  
    should "have start time today at 10 am local time" do
      assert_equal @today, @appt.start_at.to_s(:appt_schedule_day)
      assert_equal 10, @appt.start_at.hour
      assert_equal 0, @appt.start_at.min
    end
    
    should "have end time today at noon local time" do
      assert_equal @today, @appt.end_at.to_s(:appt_schedule_day)
      assert_equal 12, @appt.end_at.hour
      assert_equal 0, @appt.end_at.min
    end
  end
  
  context "create free appointment using provider with capacity 2" do
    setup do
      # create free time from 10 am to 12 pm
      @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider2, :time_range => @time_range)
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
    
    should "have a free appointment of capacity 2 and a capacity slot of capacity 2" do
      assert_equal 2, @free_appt.capacity
      assert_equal 2, @free_appt.capacity_slots.first.capacity
    end
      
    context "and schedule work appointment using service capacity 2" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider2, @work_service2, @work_service2.duration, @customer, @options)
      end
  
      should "have valid work appointment with capacity 2" do
        assert_valid @work_appt
        assert 2, @work_appt.capacity
      end
    end
  
  end
  
  #
  # Recurrence Tests
  #
  
  context "create one invalid recurring free appointment (private, no service)" do
    setup do
      @start_at       = Time.zone.now.beginning_of_day.utc
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 8.weeks
      # Recur 2 and 4 days from now
      @recur_days     = "#{ical_days([@start_at + 2.days, @start_at + 4.days])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Appointment.new(:company => @company, :customer => @customer, :provider => @provider,
                                        :start_at => @start_at, :end_at => @end_at, :public => false,
                                        :mark_as => "free", :recur_rule => @recur_rule,
                                        :description => "This is the recurrence description")
    end
    
    should "not be valid" do
      assert_false @recurrence.valid?
    end
    
    should "create no appointments or capacity slots" do
      assert_equal 0, Appointment.count
      assert_equal 0, CapacitySlot.count
    end
  
  end
    
  context "create one invalid recurring free appointment (private, no provider)" do
    setup do
      @start_at       = Time.zone.now.beginning_of_day.utc
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 8.weeks
      # Recur 2 and 4 days from now
      @recur_days     = "#{ical_days([(@start_at + 2.days), (@start_at + 4.days)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Appointment.new(:company => @company, :customer => @customer, :service => @free_service,
                                        :start_at => @start_at, :end_at => @end_at, :public => false,
                                        :mark_as => "free", :recur_rule => @recur_rule, :description => "This is the recurrence description")
    end
    
    should "not be valid" do
      assert_false @recurrence.valid?
    end
  
    should "create no appointments or capacity slots" do
      assert_equal 0, Appointment.count
      assert_equal 0, CapacitySlot.count
    end
  end
    
  context "create one valid recurring free private appointment" do
    setup do
      @start_at       = Time.zone.now.beginning_of_day
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 8.weeks
      @recur_days     = "#{ical_days([@start_at.utc, (@start_at + 4.days).utc])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = AppointmentScheduler.create_free_appointment(@company, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                     :description => "This is the recurrence description")
      assert_valid @recurrence

    end
    
    should_change("Appointment.count", :by => 1) { Appointment.count }
    should_change("CapacitySlot.count", :by => 1) { CapacitySlot.count }
    
    should_not_change("Appointment.public.count") { Appointment.public.count }
    
    should "have duration of 2 hours and start at 00:00 and finish at 02:00" do
      assert_equal 2.hours, @recurrence.duration
      assert_equal 0, @recurrence.start_at.in_time_zone.hour
      assert_equal 2, @recurrence.end_at.in_time_zone.hour
    end
    
    should "have a valid uid" do
      assert !(@recurrence.uid.blank?)
      assert_match Regexp.new("[0-9]+-[0-9]+@walnutindustries.com"), @recurrence.uid
    end
      
    context "then expand the recurring appointment" do
      setup do
        @recurrence.expand_recurrence(@end_at, @start_at + 4.weeks - 1.hour)
        @recurrence.reload
      end
      
      should "have 7 recurrence instances" do
        assert_equal 7, @recurrence.recur_instances.count
      end
  
      should_change("Appointment.count", :by => 7) { Appointment.count }
      should_change("CapacitySlot.count", :by => 7) { CapacitySlot.count }
      
      should_not_change("Appointment.public.count") { Appointment.public.count }
      
      should "have instances with duration of 2 hours and start at 00:00 and finish at 02:00" do
        @recurrence.recur_instances.each do |a|
          assert_equal 2.hours, a.duration
          assert_equal 0, a.start_at.in_time_zone.hour
          assert_equal 2, a.end_at.in_time_zone.hour
          assert_equal (0.hours - Time.zone.utc_offset) % 24.hours, a.time_start_at
          assert_equal (2.hours - Time.zone.utc_offset) % 24.hours, a.time_end_at
        end
      end
      
      should "have instances with capacity slots with a duration of 2 hours and start at 0000 and finish at 0200" do
        @recurrence.recur_instances.each do |a|
          assert_equal 2.hours, a.capacity_slots.first.duration
          assert_equal 0, a.capacity_slots.first.start_at.in_time_zone.hour
          assert_equal 2, a.capacity_slots.first.end_at.in_time_zone.hour
          assert_equal 0.hours - Time.zone.utc_offset, a.capacity_slots.first.time_start_at
          assert_equal 2.hours - Time.zone.utc_offset, a.capacity_slots.first.time_end_at
        end
      end
      
      should "have recur_expanded_to as the end date" do
        assert_equal @start_at + 4.weeks - 1.hour, @recurrence.recur_expanded_to
      end
        
      should "have instances with same attributes as recurrence" do
        @recurrence.recur_instances.each do |a|
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
      
      context "then delete the recurrence" do
         setup do
           @recur_instances = @recurrence.recur_instances.map{|i| i.id }
           @recurrence.destroy
         end
      
         should_change("Appointment.count", :by => -1) { Appointment.count }
         
         should "have 7 instances with no recurrence parent" do
           assert_equal 7, @recur_instances.count
           @recur_instances.each do |i|
             assert_nil Appointment.find(i).recur_parent
           end
         end
      
      end
      
      context "then change the recurrence description" do
        setup do
          @recurrence.description = "This is a changed recurring description"
          attr_changed = @recurrence.changed
          attr_changes = @recurrence.changes
          @recurrence.save
          @recurrence.update_recurrence(attr_changed, attr_changes)
        end
      
        should_not_change("Appointment.count") { Appointment.count }
      
        should "change appointments' description" do
          @recurrence.recur_instances.each do |a|
            assert_equal "This is a changed recurring description", a.description
          end
        end
      
      end
      
      context "then change end time and duration of the recurrence" do
        setup do
          @recurrence.end_at = @recurrence.start_at + 3.hours
          @recurrence.duration = 3.hours
          attr_changed = @recurrence.changed
          attr_changes = @recurrence.changes
          @recurrence.save
          @recurrence.update_recurrence(attr_changed, attr_changes)
          @recurrence.reload
        end
      
        should_not_change("Appointment.count") { Appointment.count }
      
        should "change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 3.hours, a.duration
            assert_equal 0, a.start_at.in_time_zone.hour
            assert_equal 3, a.end_at.in_time_zone.hour
          end
        end
      
      end
      
      context "then change the recurrence rule to 3 per week" do
        setup do
          @recur_days            = "#{ical_days([@start_at, @start_at + 3.days, @start_at + 5.days])}"
          @recur_rule            = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
          @recurrence.recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
          attr_changed = @recurrence.changed
          attr_changes = @recurrence.changes
          @recurrence.save
          @recurrence.update_recurrence(attr_changed, attr_changes)
          @recurrence.reload
        end
      
        should_change("Appointment.count", :by => 4) { Appointment.count }
      
        should "not change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 2.hours, a.duration
            assert_equal 0, a.start_at.in_time_zone.hour
            assert_equal 2, a.end_at.in_time_zone.hour
          end
        end
      
      end
      
      context "then change the recurrence rule to 3 per week and change end time" do
        setup do
          @recurrence.end_at     = @recurrence.start_at + 3.hours
          @recurrence.duration   = 3.hours
          @recur_days            = "#{ical_days([@start_at, @start_at + 3.days, @start_at + 5.days])}"
          @recurrence.recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
          attr_changed = @recurrence.changed
          attr_changes = @recurrence.changes
          @recurrence.save
          @recurrence.update_recurrence(attr_changed, attr_changes)
          @recurrence.reload
        end
      
        should_change("Appointment.count", :by => 4) { Appointment.count }
      
        should "change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 3.hours, a.duration
            assert_equal 0, a.start_at.in_time_zone.hour
            assert_equal 3, a.end_at.in_time_zone.hour
          end
        end
      
      end
      
      context "then create a second recurrence" do
        setup do
          # Create the second recurrence starting after the first (the first goes from 0000 to 0200, this second will go from 0400 to 0430)
          @start_at       = Time.zone.now.beginning_of_day + 4.hours
          @end_at         = @start_at + 30.minutes
          @end_recurrence = @start_at + 8.weeks
          @recur_days     = "#{ical_days([(@start_at + 1.day), (@start_at + 5.days)])}"
          @recur_rule     = "FREQ=WEEKLY;INTERVAL=2;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
          @recurrence2    = AppointmentScheduler.create_free_appointment(@company, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                         :description => "This is the 2nd recurrence description")
          assert_valid @recurrence2
          appointments    = @recurrence2.expand_recurrence(@start_at, @start_at + 4.weeks - 1.hour)
        end
      
        should_change("Appointment.count", :by => 5) { Appointment.count }
      
        should "have duration of 30 minutes" do
          @recurrence2.recur_instances.each do |a|
            assert_equal 30.minutes, a.duration
            assert_equal 4, a.start_at.in_time_zone.hour
            assert_equal 4, a.end_at.in_time_zone.hour
            assert_equal 30, a.end_at.min
          end
        end
      
        context "then remove company" do
          setup do
            @company.destroy
          end
      
          should "have no Companies or associated models" do
            assert_equal 0, Company.count
            assert_equal 0, Appointment.count
            assert_equal 0, Subscription.count
            assert_equal 0, CompanyProvider.count
            assert_equal 0, CapacitySlot.count
          end
        end
      end
      
      context "delete the second recurrence" do
        setup do
          setup do
            @recurrence2.destroy
          end
      
          should_change("Appointment.count", :by => -5) { Appointment.count }
        end
      
      end
      
      context "then search for available time" do
      
      end
      
      
      context "then schedule an overlapping available appointment" do
      
      end  
  

      context "create a second conflicting valid recurring free private appointment" do
        setup do
          # Each of @start_at, @end_at, @end_recurrence, @recur_days and @recur_rule are reused from previous definition
        end
      
        should "raise exception" do
          assert_raise TimeslotNotEmpty do
            @recurrence2  = AppointmentScheduler.create_free_appointment(@company, @provider, :start_at => @start_at, :end_at => @end_at, 
                                                :recur_rule => @recur_rule, :description => "This is the recurrence description")
          end
        end
      end
      
    end
    
  end
  
  context "create an available appointment" do
    
    context "and then create a recurring available appointment overlapping the existing available appointment" do
      
    end
  
  end
  
  context "create a recurring free public appointment ending in 13 days" do
    setup do
      @start_at       = Time.zone.now.beginning_of_day.utc
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 13.days
      @recur_days     = "#{ical_days([(@start_at)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = AppointmentScheduler.create_free_appointment(@company, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                     :name => "Happy Hour!", :description => "$2 beers, $3 well drinks", :public => true)
      assert_valid @recurrence
      @recurrence.expand_recurrence(@end_at, @start_at + 4.weeks)
    end
    
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should_change("Appointment.public.count", :by => 2) { Appointment.public.count }
  
  end
  
  context "create a recurring free public appointment with no end instantiating 3 instances" do
    setup do
      @start_at   = Time.zone.now.beginning_of_day.utc
      @end_at     = @start_at + 2.hours
      @recur_days = "#{ical_days([(@start_at + 3.days)])}"
      @recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
      @recurrence = AppointmentScheduler.create_free_appointment(@company, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                 :name => "Happy Hour!", :description => "$2 beers, $3 well drinks", :public => true)
      assert_valid @recurrence
      @appointments   = @recurrence.expand_recurrence(@start_at, @start_at + 4.weeks, 3)
    end
    
    should_change("Appointment.count", :by => 4) { Appointment.count }
    
    should_change("Appointment.public.count", :by => 4) { Appointment.public.count }
    
    should "have 3 appointments returned from expand_recurrence" do
      assert_equal  3, @appointments.size
    end
  
  end
  
  context "create a recurring free public appointment which ends in the past" do
    setup do
      @now            = Time.zone.now.beginning_of_day.utc
      @start_at       = @now - 6.months
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 4.weeks
      @recur_days     = "#{ical_days([(@start_at + 2.days)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = AppointmentScheduler.create_free_appointment(@company, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                     :name => "Happy Hour!", :description => "$2 beers, $3 well drinks", :public => true)
      assert_valid @recurrence
      @appointments   = @recurrence.expand_recurrence(@now, @now + 4.weeks)
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
  
  end
  
end
