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
      @johnny    = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :companies => [@company], :price => 1.00)
      @customer  = Factory(:user)

      # create free appointment (all day)
      @free_appointment   = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, 
                                                                         :start_at => "20100101000000", :end_at => "20100102000000")
      assert_valid @free_appointment

      # search for free appointments
      @daterange          = DateRange.parse_range("20100101000000", "20100301000000")
      @free_appointments  = AppointmentScheduler.find_free_appointments(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
    end
    
    should "find no free appointments" do
      assert_equal [], @free_appointments
    end
    
    context "then add a service provider and search for free appointments again" do
      setup do
        # add schedulable
        @haircut.schedulables.push(@johnny)
        # search for free appointments
        @free_appointments  = AppointmentScheduler.find_free_appointments(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
      end

      should "find 1 free appointment" do
        assert_equal [@free_appointment], @free_appointments
      end
    end
  end
  
  context "create a free appointment that has already ended" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :companies => [@company], :users => [@johnny], :price => 1.00)
      # @customer  = Factory(:user)

      # create free appointment that ended 1 hour ago
      @end_at             = (Time.now - 3.minutes).to_s(:appt_schedule)
      @start_at           = (Time.now - 10.hours).to_s(:appt_schedule)
      @free_appointment   = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
    end
    
    context "and search for free appointments" do
      setup do
        # search for free appointments using a wider date range (in utc format)
        @daterange          = DateRange.parse_range((Time.now - 3.days).utc.to_s(:appt_schedule), (Time.now + 3.days).utc.to_s(:appt_schedule))
        @free_appointments  = AppointmentScheduler.find_free_appointments(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
      end
      
      should "find no free appointments" do
        assert_equal [], @free_appointments
      end
    end
  end

  context "create a free appointment that starts in the future" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :companies => [@company], :users => [@johnny], :price => 1.00)
      # @customer  = Factory(:user)

      @haircut.reload
      @johnny.reload
      
      # create a free appointment that starts in 1 hour
      @start_at           = (Time.now + 1.hour).to_s(:appt_schedule)
      @end_at             = (Time.now + 3.hours).to_s(:appt_schedule)
      @free_appointment   = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :start_at => @start_at, :end_at => @end_at)
      assert_valid @free_appointment
    end

    context "and search for free appointments" do
      setup do
        # search for free appointments using a wider date range (in utc format)
        @daterange          = DateRange.parse_range((Time.now - 3.days).utc.to_s(:appt_schedule), (Time.now + 3.days).utc.to_s(:appt_schedule))
        @free_appointments  = AppointmentScheduler.find_free_appointments(@company, Location.anywhere, @johnny, @haircut, @haircut.duration, @daterange)
      end
      
      should "find 1 free appointment" do
        assert_equal [@free_appointment], @free_appointments
      end
    end
  end
  
  context "schedule work appointment at the start of a free appointment" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :companies => [@company], :users => [@johnny], :price => 1.00)
      @customer  = Factory(:user)

      # create free appointment (all day)
      @free_appointment  = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :start_at => "20080801000000", :end_at => "20080802000000")
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, @johnny, @haircut, @customer, :start_at => "20080801000000")
      assert_valid @work_appointment
    end
    
    # should have 1 free and 1 work appointment
    should_change "Appointment.count", :by => 2
    
    should "have work appointment with customer" do
      assert_equal @customer, @work_appointment.customer
    end
    
    should "have work appointment with haircut service" do
      assert_equal @haircut, @work_appointment.service
    end
    
    should "have work appointment with correct start and end times" do
      assert_equal "20080801T000000", @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal "20080801T003000", @work_appointment.end_at.to_s(:appt_schedule)
    end
    
    should "have work appointment with a different confirmation code" do
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
    
    context "then cancel work appointment" do
      setup do
        @free2_appointment = AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end

      # should have 1 free ppointment
      should_change "Appointment.count", :by => -1

      should "have new free appointment with same properties as free appointment" do
        assert_equal @free_appointment.start_at, @free2_appointment.start_at
        assert_equal @free_appointment.end_at, @free2_appointment.end_at
        assert_equal @free_service, @free2_appointment.service
        assert_equal @johnny, @free2_appointment.schedulable
        # customer id should be nil for a free appointment
        assert_equal nil, @free2_appointment.customer_id
      end
    end
  end
  
  context "schedule work appointment in the middle of a free appointment" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :companies => [@company], :users => [@johnny], :price => 1.00)
      @customer  = Factory(:user)

      # create free appointment (all day)
      @free_appointment  = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, :start_at => "20080801000000", :end_at => "20080802000000")
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, @johnny, @haircut, @customer, :start_at => "20080801110000")
      assert_valid @work_appointment
    end
  
    # should have 2 free and 1 work appointment
    should_change "Appointment.count", :by => 3
  
    should "have work appointment with customer" do
      assert_equal @customer, @work_appointment.customer
    end
    
    should "have work appointment with haircut service" do
      assert_equal @haircut, @work_appointment.service
    end
  
    should "have work appointment with correct start and end times" do
      assert_equal "20080801T110000", @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal "20080801T113000", @work_appointment.end_at.to_s(:appt_schedule)
    end
  
    should "have work appointment different confirmation code" do
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end
  
    context "then cancel work appointment" do
      setup do
        @free2_appointment = AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end

      # should have 1 free appointment again
      should_change "Appointment.count", :by => -2

      should "have new free appointment with same properties as free appointment" do
        assert_equal @free_appointment.start_at, @free2_appointment.start_at
        assert_equal @free_appointment.end_at, @free2_appointment.end_at
        assert_equal @free_service, @free2_appointment.service
        assert_equal @johnny, @free2_appointment.schedulable
        # customer id should be nil for a free appointment
        assert_equal nil, @free2_appointment.customer_id
      end
    end
  
  end

  context "schedule work appointment at the end of a free appointment" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :companies => [@company], :users => [@johnny], :price => 1.00)
      @customer  = Factory(:user)
      
      # create free appointment (all day)
      @free_appointment  = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, 
                                                                        :start_at => "20080801000000", :end_at => "20080802000000")
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, @johnny, @haircut, @customer, :start_at => "20080801233000")
      assert_valid @work_appointment
    end
  
    # should have 1 free and 1 work appointment
    should_change "Appointment.count", :by => 2
    
    should "have work appointment with customer" do
      assert_equal @customer, @work_appointment.customer
    end
    
    should "have work appointment with haircut service" do
      assert_equal @haircut, @work_appointment.service
    end
    
    should "have work appointment with correct start and end times" do
      assert_equal "20080801T233000", @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal "20080802T000000", @work_appointment.end_at.to_s(:appt_schedule)
    end
    
    should "have work appointment with a different confirmation code" do
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end

    context "then cancel work appointment" do
      setup do
        @free2_appointment = AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end

      # should have 1 free ppointment
      should_change "Appointment.count", :by => -1

      should "have new free appointment with same properties as free appointment" do
        assert_equal @free_appointment.start_at, @free2_appointment.start_at
        assert_equal @free_appointment.end_at, @free2_appointment.end_at
        assert_equal @free_service, @free2_appointment.service
        assert_equal @johnny, @free2_appointment.schedulable
        # customer id should be nil for a free appointment
        assert_equal nil, @free2_appointment.customer_id
      end
    end
  end
  
  context "schedule work appointment replacing a free appointment" do
    setup do
      @johnny    = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :companies => [@company], :users => [@johnny], :price => 1.00)
      @customer  = Factory(:user)

      # create free appointment (all day)
      @free_appointment  = AppointmentScheduler.create_free_appointment(@company, @johnny, @free_service, 
                                                                        :start_at => "20080801000000", :end_at => "20080801003000")
      assert_valid @free_appointment
      
      # schedule the work appointment, the free appointment should be split into free/work time
      @work_appointment = AppointmentScheduler.create_work_appointment(@company, @johnny, @haircut, @customer, :start_at => "20080801000000")
      assert_valid @work_appointment
    end
  
    # should have 1 work appointment
    should_change "Appointment.count", :by => 1
    
    should "have work appointment with customer" do
      assert_equal @customer, @work_appointment.customer
    end
    
    should "have work appointment with haircut service" do
      assert_equal @haircut, @work_appointment.service
    end
    
    should "have work appointment with correct start and end times" do
      assert_equal "20080801T000000", @work_appointment.start_at.to_s(:appt_schedule)
      assert_equal "20080801T003000", @work_appointment.end_at.to_s(:appt_schedule)
    end
    
    should "have work appointment with a different confirmation code" do
      assert_not_equal @work_appointment.confirmation_code, @free_appointment.confirmation_code
    end

    context "then cancel work appointment" do
      setup do
        @free2_appointment = AppointmentScheduler.cancel_work_appointment(@work_appointment)
      end

      # should have 1 free appointment
      should_not_change "Appointment.count"

      should "have new free appointment with same properties as free appointment" do
        assert_equal @free_appointment.start_at, @free2_appointment.start_at
        assert_equal @free_appointment.end_at, @free2_appointment.end_at
        assert_equal @free_service, @free2_appointment.service
        assert_equal @johnny, @free2_appointment.schedulable
        # customer id should be nil for a free appointment
        assert_equal nil, @free2_appointment.customer_id
      end
    end
  end
  
end
