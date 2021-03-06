require 'test_helper'

class AppointmentTest < ActiveSupport::TestCase
  
  should validate_presence_of   :company_id
  should validate_presence_of   :start_at
  should validate_presence_of   :end_at
  should validate_presence_of   :duration
  
  should allow_value('free').for(:mark_as)
  should allow_value('work').for(:mark_as)

  should belong_to              :company
  should belong_to              :service
  should belong_to              :provider
  should belong_to              :customer
  should have_one               :invoice
  should belong_to              :location
  
  should belong_to              :recur_parent
  should have_many              :recur_instances
  
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
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :time_range => @time_range)
      assert @free_appt.valid?
    end
  
    should "create in confirmed state, add 1 capacity slot" do
      assert_equal 'confirmed', @free_appt.reload.state
      assert_equal 1, CapacitySlot.count
    end

    context "then mark as completed" do
      setup do
        @free_appt.complete!
      end

      should "change state to completed, not change capacity slot count" do
        assert_equal 'completed', @free_appt.reload.state
        assert_equal 1, CapacitySlot.count
      end
    end
      
    context "then mark as canceled" do
      setup do
        @free_appt.cancel!
      end
      
      should "change state to canceled, remove capacity slot" do
        assert_equal 'canceled', @free_appt.reload.state
        assert_equal 0, CapacitySlot.count
      end
    end

    context "then mark as noshow" do
      setup do
        @free_appt.noshow!
      end
      
      should "change state to noshow, not change capacity slot count" do
        assert_equal 'noshow', @free_appt.reload.state
        assert_equal 1, CapacitySlot.count
      end
    end
  end
  
  context "create free appointment with mismatched duration and end_at values" do
    setup do
      @start_at_utc   = Time.zone.now.beginning_of_day.utc
      @end_at_utc     = @start_at_utc + 1.hour
      @start_at_day   = @start_at_utc.to_s(:appt_schedule_day)
      @daterange      = DateRange.parse_range(@start_at_day, @start_at_day)
      @appt           = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider,
                                                                     :start_at => @start_at_utc, :end_at => @end_at_utc, :duration => 2.hours)
      assert @appt.valid?
    end

    should "have duration of 2 hours, and end_at time adjusted, and capacity 1" do
      assert_equal 2.hours, @appt.duration
      assert_equal 0, @appt.start_at.in_time_zone.hour
      assert_equal 2, @appt.end_at.in_time_zone.hour
      assert_equal 1, @appt.capacity
      assert_equal 1, @company.capacity_slots.provider(@provider).general_location(Location.anywhere).first.capacity
      assert_equal 1, @company.capacity_slots.provider(@provider).general_location(Location.anywhere).count
    end
  
    should "have a valid uid" do
      assert !(@appt.uid.blank?)
      assert_match /[0-9]{8}T[0-9]{6}-([A-Z]|[0-9]){5}@walnutindustries.com/, @appt.uid
    end
  end
  
  context "unscheduled time" do
    setup do
      @start_at     = Time.zone.now.beginning_of_day + 1.hour
      @end_at       = @start_at + 23.hours
      @start_at_day = @start_at.to_s(:appt_schedule_day)
      @daterange    = DateRange.parse_range(@start_at_day, @start_at_day)
      @appt         = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert @appt.valid?
    end
      
    should "should not have a customer" do
      assert_equal nil, @appt.customer
    end
    
    should "have 1 unscheduled slot today for 23 hours starting at 1 am" do
      # build mapping of unscheduled time
      @unscheduled = @company.capacity_slots.provider(@provider)
      assert_equal 1, @unscheduled.size
      assert_equal 23.hours, @unscheduled.first.duration
      assert_equal 1, @unscheduled.first.start_at.in_time_zone.hour
      assert_equal 0, @unscheduled.first.end_at.in_time_zone.hour
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
  
  context "directly overlapping free appointments" do
    setup do
      # create free time from 10 am to 12 pm
      @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :time_range => @time_range)
      assert @free_appt.valid?
      assert_equal 1, @company.reload.capacity_slots.count
    end

    should "allow creating a conflicting free appointment, and change capacity slot capacity value to 2" do
      # create free time from 10 am to 12 pm
      @today        = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range   = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt2   = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :time_range => @time_range)
      assert @free_appt.valid?
      assert_equal 2, Appointment.count
      # should change capacity slot capacity value from 1 to 2
      assert_equal 1, @company.reload.capacity_slots.count
      assert_equal [2], @company.capacity_slots.collect(&:capacity)
    end
  end

  context "work appointment basics" do
    setup do
      # create free time from 10 am to 12 pm
      @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :time_range => @time_range)
      assert @free_appt.valid?
      assert_equal 1, @company.reload.capacity_slots.count
    end
  
    should "raise exception without a customer" do
      assert_raise ArgumentError do
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @work_service, @work_service.duration)
      end
    end
  
    should "create work appointment with 5 character confirmation code" do
      @customer   = Factory(:user)
      @options    = {:start_at => @free_appt.start_at}
      @work_appt  = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @work_service, @work_service.duration, @customer, @provider, @options)
      assert_valid @work_appt
      assert_match /([A-Z]|[0-9]){5}/, @work_appt.confirmation_code
    end
  
    should "create work appointment with 'user manager' and 'company customer' roles" do
      @customer   = Factory(:user)
      @options    = {:start_at => @free_appt.start_at}
      @work_appt  = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @work_service, @work_service.duration, @customer, @provider, @options)
      assert_valid @work_appt
      @customer.reload
      # should add roles
      assert_equal ['user manager'], @customer.roles_on(@customer).collect(&:name).sort
      assert_equal ['company customer'], @customer.roles_on(@company).collect(&:name).sort
    end
      
    should "create work appointment with custom service duration" do
      @customer   = Factory(:user)
      @options    = {:start_at => @free_appt.start_at}
      @work_appt  = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @work_service, 2.hours, @customer, @provider, @options)
      assert_valid @work_appt
      # should have custom duration
      assert_equal @work_service, @work_appt.service
      assert_equal 2.hours, @work_appt.duration
      assert_equal 10, @work_appt.start_at.hour
      assert_equal 12, @work_appt.end_at.hour

      # context "then remove company" do
      #   setup do
      #     @company.destroy
      #   end
      # 
      #   should "have no companies or associated models" do
      #     assert_equal 0, Company.count
      #     assert_equal 0, Appointment.count
      #     assert_equal 0, Subscription.count
      #     assert_equal 0, CompanyProvider.count
      #     assert_equal 0, CapacitySlot.count
      #   end
      # end
    end

    should "throw capacity error with service capacity > 1" do
      @customer   = Factory(:user)
      @options    = {:start_at => @free_appt.start_at}
      assert_raise OutOfCapacity do
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider2, @work_service2, @work_service2.duration, @customer, @provider, @options)
      end
    end
  end
  
  context "time overlap searching" do
    setup do
      # start at 2 pm, local time
      @start_at_local = Time.zone.now.beginning_of_day + 14.hours
      @start_at_utc   = @start_at_local.utc

      @appt = @company.appointments.create(:service => @work_service,
                                           :provider => @provider,
                                           :customer => @customer,
                                           :start_at => @start_at_local,
                                           :duration => @work_service.duration,
                                           :force => true)
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
  
  context "work appointment roles and privileges" do
    setup do
      # initialize roles and privileges
      BadgesInit.roles_privileges
  
      # start at 2 pm, local time
      @start_at_local = Time.zone.now.beginning_of_day + 14.hours
  
      @appt = @company.appointments.create(:service => @work_service,
                                           :provider => @provider,
                                           :customer => @customer,
                                           :start_at => @start_at_local,
                                           :duration => @work_service.duration,
                                           :force => true)
  
      assert_valid @appt
      @end_at_utc = @appt.end_at.utc
    end
  
    should "grant customer 'appointment manager' role on the appointment" do
      assert_equal ['appointment manager'], @customer.roles_on(@appt).collect(&:name).sort
    end
  end
  
  context "work appointment capacity creation" do
    setup do
      # initialize roles and privileges
      BadgesInit.roles_privileges
  
      # start at 2 pm, local time
      @start_at_local = Time.zone.now.beginning_of_day + 14.hours
    end
    
    should "raise exception, default force value" do
      assert_raise OutOfCapacity, "Not enough capacity available" do
        @appt = @company.appointments.create(:service => @work_service,
                                             :provider => @provider,
                                             :customer => @customer,
                                             :start_at => @start_at_local,
                                             :duration => @work_service.duration)
      end
    end
  
    should "raise exception, force is false" do
      assert_raise OutOfCapacity, "Not enough capacity available" do
        @appt = @company.appointments.create(:service => @work_service,
                                             :provider => @provider,
                                             :customer => @customer,
                                             :start_at => @start_at_local,
                                             :duration => @work_service.duration,
                                             :force => false)
      end
    end
  
    should "not raise exception" do
      @appt = @company.appointments.create(:service => @work_service,
                                           :provider => @provider,
                                           :customer => @customer,
                                           :start_at => @start_at_local,
                                           :duration => @work_service.duration,
                                           :force => true)
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
  
  context "free appointment using provider with capacity 2" do
    setup do
      # create free time from 10 am to 12 pm
      @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider2, :time_range => @time_range)
      assert @free_appt.valid?
    end
  
    should "have a free appointment of capacity 2 and a capacity slot of capacity 2" do
      assert_equal 2, @free_appt.capacity
      assert_equal 2, @company.capacity_slots.provider(@provider2).general_location(Location.anywhere).first.capacity
    end
    
    context "and schedule work appointment using service capacity 2" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider2, @work_service2, @work_service2.duration, @customer, @provider, @options)
      end

      should "have valid work appointment with capacity 2" do
        assert @work_appt.valid?
        assert_equal 2, @work_appt.capacity
      end
    end
  end
  
  context "test transactional behavior of appointment changes and capacity slots by creating a work appointment with no capacity, force => false" do
    setup do
      # create free time from 12 midnight to 1 am
      @today      = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range = TimeRange.new({:day => @today, :start_at => "0000", :end_at => "0100"})
      @options    = {:start_at => @time_range.start_at}
      begin
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @work_service, @work_service.duration, @customer, @provider, @options)
      rescue Exception => e
      end
    end
    
    should "not create any appointments or capacity slots" do
      assert_equal 0, Appointment.count
      assert_equal 0, CapacitySlot.count
    end
  end
  
  context "create a free appointment 0200 - 0300 and consume the capacity with work" do
    setup do
      # create free time from 12 midnight to 1 am
      @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @today, :start_at => "0200", :end_at => "0300"})
      @options        = {:start_at => @time_range.start_at}
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :time_range => @time_range)
      @work_appt      = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @work_service, 1.hour, @customer, @provider, @options)
    end
    
    should_not_change("CapacitySlot.count") { CapacitySlot.count }
    
    context "then extend the free appointment without force => true" do
      setup do
        @time_range = TimeRange.new({:day => @today, :start_at => "0200", :end_at => "0400"})
      end
  
      should "not raise an exception" do
        assert_nothing_raised do
          @free_appt.update_attributes(:end_at => @time_range.end_at)
        end
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
      @start_at       = Time.zone.now.beginning_of_day + 9.hours
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 8.weeks
      @recur_days     = "#{ical_days([@start_at.utc, (@start_at + 4.days).utc])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider,
                                                                    :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                    :description => "This is the recurrence description")
      assert @recurrence.valid?
    end

    should "mark appointment as private" do
      assert @recurrence.private?
    end

    should "have 1 capacity slot" do
      assert_equal 1, CapacitySlot.count
    end

    should "have duration of 2 hours and start at 09:00 and finish at 11:00" do
      assert_equal 2.hours, @recurrence.duration
      assert_equal 9, @recurrence.start_at.in_time_zone.hour
      assert_equal 11, @recurrence.end_at.in_time_zone.hour
    end
    
    should "have a valid uid" do
      assert !(@recurrence.uid.blank?)
      assert_match /[0-9]{8}T[0-9]{6}-([A-Z]|[0-9]){5}@walnutindustries.com/, @recurrence.uid
    end
      
    context "then expand the recurring appointment" do
      setup do
        @recurrence.expand_recurrence(@end_at, @start_at + 4.weeks - 1.hour)
        @recurrence.reload
      end

      should "have 7 recurrence instances, add 7 capacity slots" do
        assert_equal 7, @recurrence.recur_instances.count
        assert_equal 8, CapacitySlot.count
      end

      should "have instances with duration of 2 hours and start at 09:00 and finish at 11:00" do
        @recurrence.recur_instances.each do |a|
          assert_equal 2.hours, a.duration
          assert_equal 9, a.start_at.in_time_zone.hour
          assert_equal 11, a.end_at.in_time_zone.hour
          assert_equal (9.hours - a.start_at.utc_offset) % 24.hours, a.time_start_at
          assert_equal (11.hours - a.end_at.utc_offset) % 24.hours, a.time_end_at
        end
      end
      
      should "have instances with capacity slots with a duration of 2 hours and start at 09:00 and finish at 11:00" do
        @recurrence.recur_instances.each do |a|
          assert_equal 2.hours, @company.capacity_slots.provider(@provider).general_location(Location.anywhere).first.duration
          assert_equal 9, @company.capacity_slots.provider(@provider).general_location(Location.anywhere).first.start_at.in_time_zone.hour
          assert_equal 11, @company.capacity_slots.provider(@provider).general_location(Location.anywhere).first.end_at.in_time_zone.hour
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

         should "have 0 recurrence instances, and 0 capacity slots" do
           assert_equal 0, @recurrence.recur_instances.count
           assert_equal 0, CapacitySlot.count
         end
      end
      
      context "then change the recurrence description" do
        setup do
          @options = {:description => "This is a changed recurring description"}
          @recurrence.update_attributes(@options)
          @recurrence.update_recurrence(@options.keys.map(&:to_s), @options)
          work_off_delayed_jobs
          @recurrence.reload
        end

        should "not change recurrence instances count" do
          assert_equal 7, @recurrence.recur_instances.count
        end

        should "change appointments' description" do
          @recurrence.recur_instances.each do |a|
            assert_equal "This is a changed recurring description", a.description
          end
        end
      end
      
      context "then change end time and duration of the recurrence" do
        setup do
          @options = {:end_at => @recurrence.start_at + 3.hours}
          @recurrence.update_attributes(@options)
          @recurrence.update_recurrence(@options.keys.map(&:to_s), @options)
          work_off_delayed_jobs
          @recurrence.reload
        end

        should "not change recurrence instances count" do
          assert_equal 7, @recurrence.recur_instances.count
        end

        should "change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 3.hours, a.duration
            assert_equal 9, a.start_at.in_time_zone.hour
            assert_equal 12, a.end_at.in_time_zone.hour
          end
        end
      end
      
      context "then change the recurrence rule to 3 per week" do
        setup do
          @recur_days = "#{ical_days([@start_at, @start_at + 3.days, @start_at + 5.days])}"
          @recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      
          @options    = {:recur_rule => @recur_rule}
          @recurrence.update_attributes(@options)
          @recurrence.update_recurrence(@options.keys.map(&:to_s), @options)
          work_off_delayed_jobs
          @recurrence.reload
        end

        should "add 4 recurrence appointments" do
          assert_equal 11, @recurrence.recur_instances.count
        end
      
        should "not change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 2.hours, a.duration
            assert_equal 9, a.start_at.in_time_zone.hour
            assert_equal 11, a.end_at.in_time_zone.hour
          end
        end
      end
      
      context "then change the recurrence rule to 3 per week and change end time" do
        setup do
          @recur_days = "#{ical_days([@start_at, @start_at + 3.days, @start_at + 5.days])}"
          @recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
          @options    = {:end_at => @recurrence.start_at + 3.hours, :recur_rule => @recur_rule}
          @recurrence.update_attributes(@options)
          @recurrence.update_recurrence(@options.keys.map(&:to_s), @options)
          work_off_delayed_jobs
          @recurrence.reload
        end

        should "add 4 recurrence appointments" do
          assert_equal 11, @recurrence.recur_instances.count
        end
      
        should "change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 3.hours, a.duration
            assert_equal 9, a.start_at.in_time_zone.hour
            assert_equal 12, a.end_at.in_time_zone.hour
          end
        end
      end
      
      context "then create a second recurrence" do
        setup do
          # Create the second recurrence starting before the first (the first goes from 0900 to 1100, this second will go from 0400 to 0430)
          @start_at       = Time.zone.now.beginning_of_day + 4.hours
          @end_at         = @start_at + 30.minutes
          @end_recurrence = @start_at + 8.weeks
          @recur_days     = "#{ical_days([(@start_at + 1.day), (@start_at + 5.days)])}"
          @recur_rule     = "FREQ=WEEKLY;INTERVAL=2;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
          @recurrence2    = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                         :description => "This is the 2nd recurrence description")
          assert @recurrence2.valid?
          appointments    = @recurrence2.expand_recurrence(@start_at, @start_at + 4.weeks - 1.hour)
        end

        should "add 4 recurrence appointments, 5 total appointments (recur parent and instances)" do
          assert_equal 4, @recurrence2.recur_instances.count
          assert_equal 13, Appointment.count
          assert_equal 13, CapacitySlot.count
        end

        should "have duration of 30 minutes" do
          @recurrence2.recur_instances.each do |a|
            assert_equal 30.minutes, a.duration
            assert_equal 4, a.start_at.in_time_zone.hour
            assert_equal 4, a.end_at.in_time_zone.hour
            assert_equal 30, a.end_at.min
          end
        end

        context "then delete the second recurrence" do
          setup do
            @recurrence2.destroy
          end

          should "remove 5 appointments (recur parent and instances)" do
            assert_equal 8, Appointment.count
            assert_equal 8, CapacitySlot.count
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
  
      context "then search for available time" do
      
      end
      
      
      context "then schedule an overlapping available appointment" do
      
      end  
        
        
      context "create a second conflicting valid recurring free private appointment" do
        setup do
          # Each of @start_at, @end_at, @end_recurrence, @recur_days and @recur_rule are reused from previous definition
          @recurrence2  = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at,
                                :end_at => @end_at, :recur_rule => @recur_rule, :description => "This is the recurrence description")
        end
      
        should_change("Appointment.count", :by => 1) {Appointment.count}
      end
      
      context "create a second valid recurring free private appointment where the parent does not conflict but its instances do" do
        setup do
          @recurrence2    = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at + 1.day, :end_at => @end_at + 1.day, :recur_rule => @recur_rule,
                                                                         :description => "This is the 2nd recurrence description")
          assert_valid @recurrence2
          appointments    = @recurrence2.expand_recurrence(@start_at, @start_at + 4.weeks - 1.hour)
        end
        
        # Should have the parent appointment and 7 instances
        should_change("Appointment.count", :by => 8) { Appointment.count }
        
        should "have 7 recurrence instances" do
          assert_equal 7, @recurrence2.recur_instances.count
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
      @start_at       = Time.zone.now.beginning_of_day.utc + 9.hours
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 13.days
      @recur_days     = "#{ical_days([(@start_at)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                     :name => "Happy Hour!", :description => "$2 beers, $3 well drinks", :public => true)
      # Set the company's time horizon - test the recurrence expansion defaults
      @company.preferences[:time_horizon] = 4.weeks
      assert_valid @recurrence
      @recurrence.expand_recurrence
    end
    
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should_change("Appointment.public.count", :by => 2) { Appointment.public.count }
  
  end
  
  context "create a recurring free public appointment with no end instantiating 3 instances" do
    setup do
      @start_at   = Time.zone.now.beginning_of_day.utc + 9.hours
      @end_at     = @start_at + 2.hours
      @recur_days = "#{ical_days([(@start_at + 3.days)])}"
      @recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
      @recurrence = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
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
      @now            = Time.zone.now.beginning_of_day.utc + 9.hours
      @start_at       = @now - 6.months
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 4.weeks
      @recur_days     = "#{ical_days([(@start_at + 2.days)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                     :name => "Happy Hour!", :description => "$2 beers, $3 well drinks", :public => true)
      assert_valid @recurrence
      @company.preferences[:time_horizon] = 4.weeks
      # If we don't specify the start time, it will assume the end time of the recurrence, or @end_at. That's ~6 months ago.
      # Instead we specify now as the start time. We don't specify the end time, it will be @now + the time horizon.
      @appointments   = @recurrence.expand_recurrence(@now)
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
  
  end

  #
  # This tests what is actually happening in production, and so is more useful
  #
  context "create a recurring free appointment with no end and a time horizon of 4 weeks" do
    setup do
      @start_at       = Time.zone.now.tomorrow.beginning_of_day + 9.hours
      @end_at         = @start_at + 2.hours
      @recur_days     = "#{ical_days([@start_at])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};"
      @recurrence     = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at, :recur_rule => @recur_rule,
                                                                     :name => "Happy Hour!", :description => "$2 beers, $3 well drinks", :public => true)
      assert_valid @recurrence
      @company.preferences[:time_horizon] = 4.weeks
      @appointments   = @recurrence.expand_recurrence
    end
  
    should_change("Appointment.count", :by => 4) { Appointment.count }

    context "then change the time horizon to 2 weeks and re-expand" do
      setup do
        @company.preferences[:time_horizon] = 2.weeks
        @appointments   = @recurrence.expand_recurrence
      end
      
      should_not_change("Appointment.count") { Appointment.count }
      
      context "then change the time horizon to 4 weeks and re-expand" do
        setup do
          @company.preferences[:time_horizon] = 4.weeks
          @appointments   = @recurrence.expand_recurrence
        end

        should_not_change("Appointment.count") { Appointment.count }
      end
      
    end
  
  end

end
