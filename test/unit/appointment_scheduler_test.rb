require 'test/test_helper'

class AppointmentSchedulerTest < ActiveSupport::TestCase
  
  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @free_service = @company.free_service
  end
  
  context "create a free appointment and a service with no providers, and search for free appointments" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny")
      @company.providers.push(@johnny)
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :price => 1.00)
      @company.services.push(@haircut)
      @customer  = Factory(:user)
  
      # create free appointment (all day)
      @free_appointment   = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, 
                                                                         :start_at => "20100101000000", :end_at => "20100102000000")
      assert_valid @free_appointment
  
      # search for free appointments
      @daterange  = DateRange.parse_range("20100101000000", "20100301000000")
      @free_slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
    end
    
    should "find no free capacity slots" do
      assert_equal [], @free_slots
    end
    
    context "then add a service provider and search for free appointments again" do
      setup do
        # add provider
        @haircut.providers.push(@johnny)
        # search for free appointments
        @free_slots  = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
      end
  
      should "find 1 free capacity slot corresponding to the free appointment" do
        assert_equal 1, @free_slots.size
        assert_equal [@free_appointment], @free_slots.map(&:free_appointment)
      end
    end
  end
  
  context "create a free appointment that has already ended" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny")
      @company.providers.push(@johnny)
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :users => [@johnny], :price => 1.00)
  
      # create free appointment that ended a few minutes ago
      @end_at             = (Time.now.utc - 3.minutes).to_s(:appt_schedule)
      @start_at           = (Time.now.utc - 10.hours).to_s(:appt_schedule)
      @free_appointment   = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
    end
    
    context "and search for free appointments" do
      setup do
        # search for free appointments using a wider date range (in utc format)
        @daterange  = DateRange.parse_range((Time.now - 3.days).utc.to_s(:appt_schedule), (Time.now + 3.days).utc.to_s(:appt_schedule))
        @free_slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
      end
      
      should "find 1 free capacity slot" do
        assert_equal 1, @free_slots.size
        assert_equal [@free_appointment], @free_slots.map(&:free_appointment)
      end
    end
  end
  
  context "create a free appointment that starts in the future" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny")
      @company.providers.push(@johnny)
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :users => [@johnny], :price => 1.00)
  
      @haircut.reload
      @johnny.reload
      
      # create a free appointment that starts in 1 hour
      @start_at           = (Time.now + 1.hour).to_s(:appt_schedule)
      @end_at             = (Time.now + 3.hours).to_s(:appt_schedule)
      @free_appointment   = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :start_at => @start_at, :duration => 120, :end_at => @end_at)
      assert_valid @free_appointment
    end
  
    should_change "Appointment.count", :by => 1
  
    context "and search for free appointments" do
      setup do
        # search for free appointments using a wider date range (in utc format)
        @daterange  = DateRange.parse_range((Time.now - 30.days).to_s(:appt_schedule), (Time.now + 30.days).to_s(:appt_schedule))
        @free_slots = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
      end
      
      should "find 1 free appointment" do
        assert_equal 1, @free_slots.size
        assert_equal [@free_appointment], @free_slots.map(&:free_appointment)
      end
    end
  end
  
  context "schedule work appointment at the start of a free appointment" do
    setup do
  
      @johnny           = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut          = Factory(:work_service, :name => "Haircut", :duration => 30, :companies => [@company], :users => [@johnny], :price => 1.00)
      @customer         = Factory(:user)
  
      beginning_of_day  = Time.now.utc.beginning_of_day
      @start_at         = (beginning_of_day).to_s(:appt_schedule)
      @end_at           = (beginning_of_day + 1.day).to_s(:appt_schedule)

      # create free appointment (all day)
      @free_appointment = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, @johnny, @haircut, @haircut.duration, @customer, :start_at => @start_at)
      @end_appt         = (beginning_of_day + @haircut.duration.minutes).to_s(:appt_schedule)
      assert_valid @work_appointment

      @daterange        = DateRange.parse_range((beginning_of_day - 30.days).to_s(:appt_schedule), (beginning_of_day + 30.days).to_s(:appt_schedule))
      @free_slots       = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
      
    end
    
    # should have 1 free and 1 work appointment
    should_change "Appointment.count", :by => 2
    
    should "have work appointment with customer" do
      assert_equal @customer, @work_appointment.customer
    end
    
    should "have work appointment with haircut service and standard duration" do
      assert_equal @haircut, @work_appointment.service
      assert_equal 30, @work_appointment.duration
    end
    
    should "have work appointment with correct start and end times" do
      assert_equal @start_at, @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal @end_appt, @work_appointment.end_at.to_s(:appt_schedule)
    end
    
    should "have work appointment with a different confirmation code" do
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
    
    should "have 1 capacity slot which refers to the free appointment" do
      assert_equal 1, @free_slots.size
      assert_equal [@free_appointment], @free_slots.map(&:free_appointment)
    end

    context "and then cancel the work appointment" do
      setup do
        @free2_appointment = AppointmentScheduler.cancel_work_appointment(@work_appointment)

        @free_slots2 = AppointmentScheduler.find_free_capacity_slots(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
      end
  
      # should have 1 free appointment and 1 work appointment in a 'canceled' state
      should_not_change "Appointment.count"
  
      should "have new free appointment with same properties as free appointment" do
        assert_equal @free_appointment.start_at, @free2_appointment.start_at
        assert_equal @free_appointment.end_at, @free2_appointment.end_at
        assert_equal @free_service, @free2_appointment.service
        assert_equal @johnny, @free2_appointment.provider
        # customer id should be nil for a free appointment
        assert_equal nil, @free2_appointment.customer_id
      end
      
      should "have work appointment in canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end

      should "have 1 capacity slot which refers to the free appointment" do
        assert_equal 1, @free_slots2.size
        assert_equal [@free_appointment], @free_slots2.map(&:free_appointment)
      end
    end
  end
  
  context "schedule work appointment with a custom duration in the middle of a free appointment" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny")
      @company.providers.push(@johnny)
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :users => [@johnny], :price => 1.00)
      @company.services.push(@haircut)
      @customer  = Factory(:user)
  
      # create free appointment (all day)
      @free_appointment  = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service,
                                                                        :start_at => "20080801000000", :end_at => "20080802000000")
      assert_valid @free_appointment
      
      # schedule the work appointment, with a custom duration
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, @johnny, @haircut, 60, @customer, :start_at => "20080801100000")
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change "Appointment.count", :by => 2
  
    should "have work appointment with customer" do
      assert_equal @customer, @work_appointment.customer
    end
    
    should "have work appointment with haircut service and custom duration" do
      assert_equal @haircut, @work_appointment.service
      assert_equal 60, @work_appointment.duration
    end
  
    should "have work appointment with correct start and end times" do
      assert_equal "20080801T100000", @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal "20080801T110000", @work_appointment.end_at.to_s(:appt_schedule)
    end
  
    should "have work appointment with a different confirmation code" do
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    context "and then cancel the work appointment" do
      setup do
        @free2_appointment = AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment, and 1 work appointment in a 'canceled' state
      should_not_change "Appointment.count"
  
      should "have new free appointment with same properties as free appointment" do
        assert_equal @free_appointment.start_at, @free2_appointment.start_at
        assert_equal @free_appointment.end_at, @free2_appointment.end_at
        assert_equal @free_service, @free2_appointment.service
        assert_equal @johnny, @free2_appointment.provider
        # customer id should be nil for a free appointment
        assert_equal nil, @free2_appointment.customer_id
      end
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
    end
  
  end
  
  context "schedule work appointment at the end of a free appointment" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny")
      @company.providers.push(@johnny)
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :users => [@johnny], :price => 1.00)
      @company.services.push(@haircut)
      @customer  = Factory(:user)
      
      # create free appointment (all day)
      @free_appointment  = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, 
                                                                        :start_at => "20080801000000", :end_at => "20080802000000")
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, @johnny, @haircut, @haircut.duration, @customer, :start_at => "20080801233000")
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change "Appointment.count", :by => 2
    
    should "have work appointment with customer" do
      assert_equal @customer, @work_appointment.customer
    end
    
    should "have work appointment with haircut service and standard duration" do
      assert_equal @haircut, @work_appointment.service
      assert_equal 30, @work_appointment.duration
    end
    
    should "have work appointment with correct start and end times" do
      assert_equal "20080801T233000", @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal "20080802T000000", @work_appointment.end_at.to_s(:appt_schedule)
    end
    
    should "have work appointment with a different confirmation code" do
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    context "and then cancel the work appointment" do
      setup do
        @free2_appointment = AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment + 1 work appointment, so the total number of appointments should not change
      should_not_change "Appointment.count"
  
      should "have new free appointment with same properties as free appointment" do
        assert_equal @free_appointment.start_at, @free2_appointment.start_at
        assert_equal @free_appointment.end_at, @free2_appointment.end_at
        assert_equal @free_service, @free2_appointment.service
        assert_equal @johnny, @free2_appointment.provider
        # customer id should be nil for a free appointment
        assert_equal nil, @free2_appointment.customer_id
      end
  
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
    end
  end
  
  context "schedule work appointment replacing a free appointment" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny")
      @company.providers.push(@johnny)
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :users => [@johnny], :price => 1.00)
      @company.services.push(@haircut)
      @customer  = Factory(:user)
  
      # create free appointment (all day)
      @free_appointment  = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, 
                                                                        :start_at => "20080801000000", :end_at => "20080801003000")
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, @johnny, @haircut, @haircut.duration, @customer, :start_at => "20080801000000")
      assert_valid @work_appointment
    end
  
    # should have 1 work appointment and 1 free appointment
    should_change "Appointment.count", :by => 2
    
    should "have work appointment with customer" do
      assert_equal @customer, @work_appointment.customer
    end
    
    should "have work appointment with haircut service and standard duration" do
      assert_equal @haircut, @work_appointment.service
      assert_equal 30, @work_appointment.duration
    end
    
    should "have work appointment with correct start and end times" do
      assert_equal "20080801T000000", @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal "20080801T003000", @work_appointment.end_at.to_s(:appt_schedule)
    end
    
    should "have work appointment with a different confirmation code" do
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    context "and then cancel the work appointment" do
      setup do
        @free2_appointment = AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end
  
      # should have 1 free appointment + 1 work appointment in a canceled state
      should_not_change "Appointment.count"
  
      should "have new free appointment with same properties as free appointment" do
        assert_equal @free_appointment.start_at, @free2_appointment.start_at
        assert_equal @free_appointment.end_at, @free2_appointment.end_at
        assert_equal @free_service, @free2_appointment.service
        assert_equal @johnny, @free2_appointment.provider
        # customer id should be nil for a free appointment
        assert_equal nil, @free2_appointment.customer_id
      end
      
      should "have work appointment in a canceled state" do
        @work_appointment.reload
        assert_equal "canceled", @work_appointment.state
      end
    end
  end
  
end
