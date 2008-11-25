require 'test/test_helper'
require 'test/factories'

class AppointmentScheduleTest < ActiveSupport::TestCase

  def test_should_schedule_work
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company)
    haircut   = Factory(:work_service, :name => "Haircut", :duration => 30, :company => company)
    customer  = Factory(:customer)
    
    # create big fee timeslot
    free_appointment = Appointment.create(:company => company, 
                                          :service => free,
                                          :person => johnny,
                                          :customer_id => 0,
                                          :start_at => "20080801000000",
                                          :end_at =>   "20080802000000")  # free all day
    assert free_appointment.valid?
    
    # create new appointment object for a haircut
    new_appointment = Appointment.new(:company => company,
                                      :service => haircut,
                                      :person => johnny,
                                      :customer => customer,
                                      :start_at => "20080801000000",
                                      :duration =>  haircut.duration)
                                      
    assert new_appointment.valid?
    
    # should be conflicts
    assert new_appointment.conflicts?
    
    assert_difference('Appointment.count', 1) do
      # schedule the work appointment, the free appointment should be split into free/work time
      work_appointment = AppointmentScheduler.create_work_appointment(new_appointment)
      assert work_appointment.valid?
      # work appointment should have the correct customer and job
      assert_equal customer, work_appointment.customer
      assert_equal haircut, work_appointment.service
    end
  end

  def test_should_schedule_job_at_start_of_available_timeslot
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company)
    customer  = Factory(:customer)
    
    # create big available timeslot
    available_appt = Appointment.create(:company => company, 
                                        :service => free,
                                        :person => johnny,
                                        :customer => customer,
                                        :start_at => "20080801000000",
                                        :end_at =>   "20080802000000")  # available all day
    
    # split appointment
    haircut           = Factory(:work_service, :name => "Haircut", :duration => 30, :company => company)
    haircut_start_at  = "20080801000000" # 12:00 am
    haircut_end_at    = "20080801003000" # 12:30 am, 30 minutes

    assert_no_difference('Appointment.count') do
      appts         = AppointmentScheduler.split_free_appointment(available_appt, haircut, haircut_start_at, haircut_end_at)
  
      # should now have 2 appointments
      assert_equal 2, appts.size
      new_appt    = appts[0]
      end_appt    = appts[1]
  
      # new appointment should have the specified service
      assert_equal haircut, new_appt.service

      # new appointment should match job start, end time
      assert_equal Time.zone.parse(haircut_start_at), new_appt.start_at
      assert_equal Time.zone.parse(haircut_end_at), new_appt.end_at
      # new appointment should be marked as work
      assert_equal 'work', new_appt.mark_as
    
      # end appointment should start when new appointment ends
      assert_equal new_appt.end_at, end_appt.start_at
      assert_equal available_appt.end_at, end_appt.end_at
      assert_equal 'free', end_appt.mark_as
    end

  end
  
  def test_should_schedule_job_in_middle_of_available_timeslot
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company)
    customer  = Factory(:customer)
    
    # create big available timeslot
    available_appt = Appointment.create(:company => company, 
                                        :service => free,
                                        :person => johnny,
                                        :customer => customer,
                                        :start_at => "20080801000000",
                                        :end_at =>   "20080802000000")  # available all day
    
    haircut           = Factory(:work_service, :name => "Haircut", :duration => 30, :company => company)
    haircut_start_at  = "20080801120000" # 12 pm
    haircut_end_at    = "20080801123000" # 12:30 pm, 30 minutes
    
    assert_no_difference('Appointment.count') do
      # split appointment, no commit
      appts         = AppointmentScheduler.split_free_appointment(available_appt, haircut, haircut_start_at, haircut_end_at)
    
      # should now have 3 appointments
      assert_equal 3, appts.size
      start_appt    = appts[0]
      work_appt     = appts[1]
      end_appt      = appts[2]
    
      # new appointment should have the specified service
      assert_equal haircut, work_appt.service
    
      # start appointment should end when new appointment starts
      assert_equal available_appt.start_at, start_appt.start_at
      assert_equal work_appt.start_at, start_appt.end_at
      assert_equal 'free', start_appt.mark_as
      # free time duration should be adjusted
      assert_equal 1440-30, start_appt.duration
      
      # work appointment should match job start, end times
      assert_equal Time.zone.parse(haircut_start_at), work_appt.start_at
      assert_equal Time.zone.parse(haircut_end_at), work_appt.end_at
      # work appointment should be marked as work
      assert_equal 'work', work_appt.mark_as
      assert_equal 30, work_appt.duration
      
      # end appointment should start when new appointment ends
      assert_equal work_appt.end_at, end_appt.start_at
      assert_equal available_appt.end_at, end_appt.end_at
      assert_equal 'free', end_appt.mark_as
      # free time duration should be adjusted
      assert_equal 1440-30, end_appt.duration
    end
    
    assert_difference('Appointment.count', 2) do
      # split, commit appointment
      appts = AppointmentScheduler.split_free_appointment(available_appt, haircut, haircut_start_at, haircut_end_at, :commit => 1)
    end
  end

  def test_should_schedule_job_at_end_of_available_timeslot
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company)
    customer  = Factory(:customer)
    
    # create big available timeslot
    available_appt = Appointment.create(:company => company, 
                                        :service => free,
                                        :person => johnny,
                                        :customer => customer,
                                        :start_at => "20080801000000",
                                        :end_at =>   "20080802000000")  # available all day
    
    # split appointment
    haircut           = Factory(:work_service, :name => "Haircut", :duration => 30, :company => company)
    haircut_start_at  = "20080801002330" # 11:30 pm
    haircut_end_at    = "20080802000000" # 12:00 am, 30 minutes
      
    assert_no_difference('Appointment.count') do
      appts         = AppointmentScheduler.split_free_appointment(available_appt, haircut, haircut_start_at, haircut_end_at)
  
      # should now have 2 appointments
      assert_equal 2, appts.size
      start_appt    = appts[0]
      new_appt      = appts[1]
  
      # new appointment should have the specified service
      assert_equal haircut, new_appt.service
    
      # start appointment should end when new appointment starts
      assert_equal available_appt.start_at, start_appt.start_at
      assert_equal new_appt.start_at, start_appt.end_at
      assert_equal 'free', start_appt.mark_as
  
      # new appointment should match job start, end time
      assert_equal Time.zone.parse(haircut_start_at), new_appt.start_at
      assert_equal Time.zone.parse(haircut_end_at), new_appt.end_at
      # new appointment should be marked as work
      assert_equal 'work', new_appt.mark_as
    end

    assert_difference('Appointment.count', 1) do
      # split, commit appointment
      appts = AppointmentScheduler.split_free_appointment(available_appt, haircut, haircut_start_at, haircut_end_at, :commit => 1)
    end
  end

  def test_should_create_free_appointment
    # should create free time for the entire day
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    lisa      = Factory(:person, :name => "Lisa", :companies => [company])
    free      = Factory(:free_service, :company => company)
    
    start_at  = Time.now.beginning_of_day
    end_at    = start_at + 1.day
    appt      = AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
    assert appt.valid?
    assert_equal 24 * 60, appt.duration
    
    assert_raise TimeslotNotEmpty do
      # should throw error
      AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
    end
    
    # should create free time for another resource
    appt  = AppointmentScheduler.create_free_appointment(company, lisa, start_at, end_at)
    assert appt.valid?
    assert_equal 24 * 60, appt.duration
  end

end