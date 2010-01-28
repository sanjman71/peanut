require 'test/test_helper'

class AppointmentSchedulerTest < ActiveSupport::TestCase
  
  def setup
    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @free_service   = @company.free_service
    @provider       = Factory(:user, :name => "Provider")
    @haircut        = Factory(:work_service, :name => "Haircut", :duration => 1.hour, :price => 1.00, :company => @company)
    @customer       = Factory(:user, :name => "Customer")

    @location       = Location.anywhere
    @start_tomorrow = Time.zone.now.tomorrow.beginning_of_day
    @start_today    = Time.zone.now.beginning_of_day

    @daterange      = DateRange.parse_range((@start_tomorrow - 30.days).to_s(:appt_schedule), (@start_tomorrow + 30.days).to_s(:appt_schedule))

  end
  
  #
  # Check the find_free_capacity_slots function
  #
  context "create a free appointment and a service with no providers, and search for available capacity" do
    setup do
      @company.user_providers.push(@provider)
      @company.services.push(@haircut)
      
      @start_at         = @start_tomorrow.to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
  
      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
  
      # search for free capacity
      @daterange        = DateRange.parse_range(@start_at, @end_at)
    end
    
    should "find no free capacity slots" do
      slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [], slots
    end
    
    context "then add a service provider and search for free appointments again" do
      setup do
        # add provider
        @haircut.user_providers.push(@provider)
      end
  
      should "find 1 slot 0 8 c 1" do
        slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
    end
  end
  
  context "create a free appointment that has already ended" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      # create free appointment that ended a few minutes ago
      @start_at         = (@start_tomorrow - 2.days).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow - 2.days + 8.hours).to_s(:appt_schedule)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
    end
    
    context "and search for free appointments" do
      should "find no slots without :keep_old => true" do
        slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [], slots
      end
  
      should "find 1 slot 0 8 c 1 with :keep_old => true" do
        slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange, :keep_old => true).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
    end
  end
  
  context "create a free appointment that starts in the future" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
      @haircut.reload
      @provider.reload
      
      # create a free appointment that starts tomorrow
      @start_at           = (@start_tomorrow).to_s(:appt_schedule)
      @end_at             = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
      @free_appointment   = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
  
    context "and search for free capacity slots" do
      should "find 1 slot 0 8 c 1" do
        slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
  
    end
  end
  
  context "schedule work appointments (capacity 1 and 2) throughout a free appointment of capacity 3" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
  
      # create free appointment
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at, :capacity => 3)
      assert_valid @free_appointment
      
      AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 1.hour, @customer, :start_at => (@start_tomorrow + 0.hours).to_s(:appt_schedule), :capacity => 1)
      AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 2.hours, @customer, :start_at => (@start_tomorrow + 1.hours).to_s(:appt_schedule), :capacity => 2)
      AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 1.hour, @customer, :start_at => (@start_tomorrow + 2.hours).to_s(:appt_schedule), :capacity => 1)
      AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 2.hours, @customer, :start_at => (@start_tomorrow + 5.hours).to_s(:appt_schedule), :capacity => 1)
    end

    should "have 1 slot from after the work appointment to end of day capacity 1" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 1, 1.hours, 2], [1, 2, 1.hour, 1], [3, 5, 2.hours, 3], [5, 7, 2.hours, 2], [7, 8, 1.hours, 3]], slots
    end

    should "find free capacity slots capacity 1" do
      slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange, :capacity => 1).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 2, 2.hours, 1], [3, 8, 5.hours, 2]], slots
    end

    should "find free capacity slots capacity 2" do
      slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange, :capacity => 2).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 1, 1.hour, 2], [3, 8, 5.hours, 2]], slots
    end

    should "find free capacity slots capacity 3" do
      slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange, :capacity => 3).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[3, 5, 2.hours, 3], [7, 8, 1.hours, 3]], slots
    end

    should "find free capacity slots capacity 4" do
      slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @daterange, :capacity => 4).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [], slots
    end



  end
  
  #
  # Check scheduling work in various places around a free appointment
  #
  context "schedule work appointment at the start of a free appointment" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
  
      # create free appointment
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @customer, :start_at => @start_at)
      @end_appt         = (@start_tomorrow + @haircut.duration).to_s(:appt_schedule)
      assert_valid @work_appointment
  
      
    end
    
    # should have 1 free and 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have work appointment with customer, haircut service, correct duration, correct start and end times, different conf code" do
      assert_equal @customer, @work_appointment.customer
      assert_equal @haircut, @work_appointment.service
      assert_equal @haircut.duration, @work_appointment.duration
      assert_equal @start_at, @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal @end_appt, @work_appointment.end_at.to_s(:appt_schedule)
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
    
    should "have 1 slot from after the work appointment to end of day capacity 1" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[1, 8, 7.hours, 1]], slots
    end
  
    context "and then cancel the work appointment" do
      setup do
        AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
      
      # should have 1 free appointment and 1 work appointment in a 'canceled' state
      should_not_change("Appointment.count") { Appointment.count }
      
      should "have work appointment in canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
      
      should "have 1 slot from after the work appointment to end of day capacity 1" do
        slots = @company.capacity_slots.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
  
    end
  end
  
  context "schedule work appointment with a custom duration in the middle of a free appointment" do
    setup do
      @company.company_providers.create(:provider => @provider)
      @haircut.service_providers.create(:provider => @provider)
  
      # create free appointment (all day)
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
      @start_work       = (@start_tomorrow + 4.hours).to_s(:appt_schedule)
  
      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
      
      # schedule the work appointment, with a custom duration
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 2.hours, @customer, :start_at => @start_work)
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
  
    should "have work appointment with customer, haircut service, correct duration, correct start and end times, different conf code" do
      assert_equal @customer, @work_appointment.customer
      assert_equal @haircut, @work_appointment.service
      assert_equal 2.hours, @work_appointment.duration
      assert_equal @start_tomorrow + 4.hours, @work_appointment.start_at
      assert_equal @start_tomorrow + 6.hours, @work_appointment.end_at
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    should "have 2 capacity slots from start of free time to start of work appt, end of work appt to end of free time" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 4, 4.hours, 1], [6, 8, 2.hours, 1]], slots
    end
  
    context "and then cancel the work appointment" do
      setup do
        AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment, and 1 work appointment in a 'canceled' state
      should_not_change("Appointment.count") { Appointment.count }
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
  
      should "have 1 slot 0 8 c 1" do
        slots = @company.capacity_slots.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
  
    end
  
  end
  
  context "schedule work appointment at the end of a free appointment" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      # create free appointment (all day)
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
      @start_work       = (@start_tomorrow + 8.hours - 1.hour).to_s(:appt_schedule)
  
      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 1.hour, @customer, :start_at => @start_work)
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have work appointment with customer, haircut service, correct duration, correct start and end times, different conf code" do
      assert_equal @customer, @work_appointment.customer
      assert_equal @haircut, @work_appointment.service
      assert_equal @haircut.duration, @work_appointment.duration
      assert_equal (@start_tomorrow + 8.hours - @haircut.duration), @work_appointment.start_at
      assert_equal @start_tomorrow + 8.hours, @work_appointment.end_at
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    should "have 1 slot 0 7 c 1" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 7, 7.hours, 1]], slots
    end
  
    context "and then cancel the work appointment" do
      setup do
        AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment + 1 work appointment, so the total number of appointments should not change
      should_not_change("Appointment.count") { Appointment.count }
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
  
      should "have 1 slot 0 8 c 1" do
        slots = @company.capacity_slots.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
  
    end
  end
  
  context "schedule work appointment covering an entire free appointment" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      # create free appointment (all day)
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + @haircut.duration).to_s(:appt_schedule)
  
      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, @haircut.duration, @customer, :start_at => @start_at)
      assert_valid @work_appointment
    end
  
    # should have 1 work appointment and 1 free appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have work appointment with customer, haircut service, correct duration, correct start and end times, different conf code" do
      assert_equal @customer, @work_appointment.customer
      assert_equal @haircut, @work_appointment.service
      assert_equal @haircut.duration, @work_appointment.duration
      assert_equal @free_appointment.start_at, @work_appointment.start_at
      assert_equal @free_appointment.end_at, @work_appointment.end_at
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    should "have no slots" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [], slots
    end
  
    context "and then cancel the work appointment" do
      setup do
        AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment + 1 work appointment in a canceled state
      should_not_change("Appointment.count") { Appointment.count }
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
  
      should "have 1 slot 0 1 c 1" do
        slots = @company.capacity_slots.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 1, 1.hour, 1]], slots
      end
  
    end
  end
  
  
  context "schedule work appointment across the end of a free appointment with force" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      # create free appointment (all day)
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
      @start_work       = (@start_tomorrow + 8.hours - 1.hour).to_s(:appt_schedule)
  
      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
  
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 2.hours, @customer, {:start_at => @start_work}, {:force => true})
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have work appointment with customer, haircut service, correct duration, correct start and end times, different conf code" do
      assert_equal @customer, @work_appointment.customer
      assert_equal @haircut, @work_appointment.service
      assert_equal 2.hours, @work_appointment.duration
      assert_equal (@start_tomorrow + 8.hours - 1.hour), @work_appointment.start_at
      assert_equal @start_tomorrow + 9.hours, @work_appointment.end_at
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    should "have 2 slots 0 7 c 1; 8 9 c -1" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 7, 7.hours, 1], [8, 9, 1.hour, -1]], slots
    end
  
    context "and then cancel the work appointment" do
      setup do
        AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment + 1 work appointment, so the total number of appointments should not change
      should_not_change("Appointment.count") { Appointment.count }
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
  
      should "have 1 slot 0 8 c 1" do
        slots = @company.capacity_slots.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
  
    end
  end
  
  context "schedule work appointment after the end of a free appointment with force" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      # create free appointment (all day)
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
      @start_work       = (@start_tomorrow + 8.hours + 1.hour).to_s(:appt_schedule)
  
      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
  
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 2.hours, @customer, {:start_at => @start_work}, {:force => true})
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have work appointment with customer, haircut service, correct duration, correct start and end times, different conf code" do
      assert_equal @customer, @work_appointment.customer
      assert_equal @haircut, @work_appointment.service
      assert_equal 2.hours, @work_appointment.duration
      assert_equal (@start_tomorrow + 8.hours + 1.hour), @work_appointment.start_at
      assert_equal (@start_tomorrow + 8.hours + 3.hours), @work_appointment.end_at
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    should "have 2 slots 0 8 c 1; 9 11 c -1" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 8, 8.hours, 1], [9, 11, 2.hours, -1]], slots
    end
  
    context "and then cancel the work appointment" do
      setup do
        AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment + 1 work appointment, so the total number of appointments should not change
      should_not_change("Appointment.count") { Appointment.count }
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
  
      should "have 1 slot 0 8 c 1" do
        slots = @company.capacity_slots.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
  
    end
  end
  
  context "schedule work appointment across the beginning of a free appointment with force" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      # create free appointment (all day)
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
      @start_work       = (@start_tomorrow - 1.hour).to_s(:appt_schedule)
  
      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
  
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 2.hours, @customer, {:start_at => @start_work}, {:force => true})
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have work appointment with customer, haircut service, correct duration, correct start and end times, different conf code" do
      assert_equal @customer, @work_appointment.customer
      assert_equal @haircut, @work_appointment.service
      assert_equal 2.hours, @work_appointment.duration
      assert_equal (@start_tomorrow - 1.hour), @work_appointment.start_at
      assert_equal (@start_tomorrow + 1.hour), @work_appointment.end_at
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    should "have 2 slots 0 7 c 1; 8 9 c -1" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[1, 8, 7.hours, 1], [23, 0, 1.hour, -1]], slots
    end
  
    context "and then cancel the work appointment" do
      setup do
        AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment + 1 work appointment, so the total number of appointments should not change
      should_not_change("Appointment.count") { Appointment.count }
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
  
      should "have 1 slot 0 8 c 1" do
        slots = @company.capacity_slots.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
  
    end
  end
  
  context "schedule work appointment before the beginning of a free appointment with force" do
    setup do
      @company.user_providers.push(@provider)
      @haircut.user_providers.push(@provider)
  
      # create free appointment (all day)
      @start_at         = (@start_tomorrow).to_s(:appt_schedule)
      @end_at           = (@start_tomorrow + 8.hours).to_s(:appt_schedule)
      @start_work       = (@start_tomorrow - 3.hours).to_s(:appt_schedule)
  
      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
  
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @haircut, 2.hours, @customer, {:start_at => @start_work}, {:force => true})
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should "have work appointment with customer, haircut service, correct duration, correct start and end times, different conf code" do
      assert_equal @customer, @work_appointment.customer
      assert_equal @haircut, @work_appointment.service
      assert_equal 2.hours, @work_appointment.duration
      assert_equal (@start_tomorrow - 3.hours), @work_appointment.start_at
      assert_equal (@start_tomorrow - 1.hour), @work_appointment.end_at
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    should "have 2 slots 0 7 c 1; 8 9 c -1" do
      slots = @company.capacity_slots.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 8, 8.hours, 1], [21, 23, 2.hours, -1]], slots
    end
  
    context "and then cancel the work appointment" do
      setup do
        AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment + 1 work appointment, so the total number of appointments should not change
      should_not_change("Appointment.count") { Appointment.count }
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
  
      should "have 1 slot 0 8 c 1" do
        slots = @company.capacity_slots.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 8, 8.hours, 1]], slots
      end
  
    end
  end

end
