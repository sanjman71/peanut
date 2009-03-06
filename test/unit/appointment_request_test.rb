require 'test/test_helper'

class AppointmentRequestTest < ActiveSupport::TestCase
  
  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
  end
  
  context "create service without anyone who performs the service and create free time" do
    setup do
      # create free time from 8 am to noon
      @company   = Factory(:company, :subscription => @subscription)
      @johnny    = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut   = Factory(:work_service, :name => "Haircut", :companies => [@company], :price => 1.00)
      @free      = @company.services.free.first
      @anyone    = User.anyone

      @start_at  = Time.now.beginning_of_day + 8.hours
      @end_at    = @start_at + 4.hours
      @appt      = AppointmentScheduler.create_free_appointment(@company, @johnny, @company.free_service, :start_at => @start_at, :end_at => @end_at)
      assert @appt.valid?
    end
    
    context "and request appointment for a specific service but no specific schedulable" do
      setup do
        @request  = AppointmentRequest.new(:start_at => @start_at + 2.hours, :end_at => @end_at + 2.hours, :company => @company,
                                           :service => @haircut, :schedulable => @anyone)
      end
      
      should "find no free appointments" do
        assert_equal [], @request.find_free_appointments
      end
    end
    
    context "and request appointment for a specific service with a specific schedulable, with time range from 10 am to 2 pm" do
      setup do
        @request = AppointmentRequest.new(:start_at => @start_at + 2.hours, :end_at => @end_at + 2.hours, :company => @company, 
                                           :service => @haircut, :schedulable => @johnny)
        
      end
      
      should "find no free appointments" do
        assert_equal [], @request.find_free_appointments
      end
    end
    
    context "add user schedulable who provides the service" do
      setup do
        @haircut.schedulables.push(@johnny)
        @haircut.reload
      end
      
      context "and make the same appointment request" do
        setup do
          @request = AppointmentRequest.new(:start_at => @start_at + 2.hours, :end_at => @end_at + 2.hours, :company => @company, 
                                             :service => @haircut, :schedulable => @johnny)

        end
        
        should "now find free appointments" do
          assert_equal [@appt], @request.find_free_appointments
        end
        
        should "find all free time slots within the appointment request range" do
          @timeslots = @request.find_free_timeslots
          assert_equal 4, @timeslots.size
          assert_equal @appt, @timeslots[0].appointment
          assert_equal 30, @timeslots[0].duration
          assert_equal Chronic.parse("today 10:00 am"), @timeslots[0].start_at
          assert_equal Chronic.parse("today 10:30 am"), @timeslots[0].end_at
          assert_equal 30, @timeslots[1].duration
          assert_equal Chronic.parse("today 10:30 am"), @timeslots[1].start_at
          assert_equal Chronic.parse("today 11:00 am"), @timeslots[1].end_at
          assert_equal 30, @timeslots[2].duration
          assert_equal Chronic.parse("today 11:00 am"), @timeslots[2].start_at
          assert_equal Chronic.parse("today 11:30 am"), @timeslots[2].end_at
          assert_equal 30, @timeslots[3].duration
          assert_equal Chronic.parse("today 11:30 am"), @timeslots[3].start_at
          assert_equal Chronic.parse("today 12:00 pm"), @timeslots[3].end_at
        end
        
        context "request appointment from 7 am to 5 pm" do
          setup do
            @request = AppointmentRequest.new(:start_at => @start_at - 1.hour, :end_at => @end_at + 5.hours, :company => @company,
                                              :service => @haircut, :schedulable => @johnny)
          end
          
          should "find 8 time slots of 30 minutes each, with start times incremented by 30 minutes" do
            @timeslots = @request.find_free_timeslots
            assert_equal 8, @timeslots.size
            assert_equal 30, @timeslots[0].duration
            assert_equal Chronic.parse("today 8:00 am"), @timeslots[0].start_at
            assert_equal Chronic.parse("today 8:30 am"), @timeslots[0].end_at
          end
        end
        
        context "request appointment from noon to 5 pm" do
          setup do
            @request = AppointmentRequest.new(:start_at => @start_at + 4.hours, :end_at => @end_at + 5.hours, :company => @company, 
                                              :service => @haircut, :schedulable => @johnny)
          end

          should "find 0 time slots" do
            @timeslots = @request.find_free_timeslots
            assert_equal 0, @timeslots.size
          end
        end
      end
    end 
  end
  
end