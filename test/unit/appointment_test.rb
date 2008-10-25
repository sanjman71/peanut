require 'test/test_helper'

class AppointmentTest < ActiveSupport::TestCase
  fixtures :companies, :jobs, :resources
  
  # shoulda
  should_require_attributes :company_id
  should_require_attributes :job_id
  should_require_attributes :resource_id
  should_require_attributes :customer_id
  should_require_attributes :start_at
  should_require_attributes :end_at

  def test_should_not_allow_start_at_equal_end_at
    appt = Appointment.create(:company => companies(:company1), 
                                      :job => jobs(:available),
                                      :resource => resources(:johnny),
                                      :customer => customers(:cameron),
                                      :start_at => "20080802000000",
                                      :end_at =>   "20080802000000")
    assert !appt.valid?
    assert_match /appointment start time/, appt.errors[:base]
  end

  def test_should_not_allow_start_at_after_end_at
    appt = Appointment.create(:company => companies(:company1), 
                                      :job => jobs(:available),
                                      :resource => resources(:johnny),
                                      :customer => customers(:cameron),
                                      :start_at => "20080802000000",
                                      :end_at =>   "20080801010000")
    assert !appt.valid?
    assert_match /appointment start time/, appt.errors[:base]
  end
  
  def test_should_set_duration
    appt = Appointment.create(:company => companies(:company1), 
                                      :job => jobs(:available),
                                      :resource => resources(:johnny),
                                      :customer => customers(:cameron),
                                      :start_at => "20080801000000",
                                      :end_at =>   "20080801010000") # 1 hour
    assert appt.valid?
    assert_equal 60, appt.duration
  end
  
  def test_should_schedule_job_in_middle_of_available_timeslot
    # create big available timeslot
    available_appt = Appointment.create(:company => companies(:company1), 
                                        :job => jobs(:available),
                                        :resource => resources(:johnny),
                                        :customer => customers(:cameron),
                                        :start_at => "20080801000000",
                                        :end_at =>   "20080802000000")  # available all day
    

    job           = jobs(:haircut)
    job_start_at  = "20080801120000"
    job_end_at    = "20080801123000" # 30 minutes
    
    assert_no_difference('Appointment.count') do
      # split appointment, no commit
      appts         = available_appt.split(job, job_start_at, job_end_at)
    
      # should now have 3 appointments
      assert_equal 3, appts.size
      start_appt    = appts[0]
      new_appt      = appts[1]
      end_appt      = appts[2]
    
      # new appointment should have the specified job
      assert_equal job, new_appt.job
    
      # start appointment should end when new appointment starts
      assert_equal available_appt.start_at, start_appt.start_at
      assert_equal new_appt.start_at, start_appt.end_at
    
      # new appointment should match job start, end times
      assert_equal Time.zone.parse(job_start_at), new_appt.start_at
      assert_equal Time.zone.parse(job_end_at), new_appt.end_at
    
      # end appointment should start when new appointment ends
      assert_equal new_appt.end_at, end_appt.start_at
      assert_equal available_appt.end_at, end_appt.end_at
    end
    
    assert_difference('Appointment.count', 2) do
      # split, commit appointment
      appts = available_appt.split(job, job_start_at, job_end_at, :commit => 1)
    end
  end
  
  def test_should_schedule_job_at_start_of_available_timeslot
    # create big available timeslot
    available_appt = Appointment.create(:company => companies(:company1), 
                                        :job => jobs(:available),
                                        :resource => resources(:johnny),
                                        :customer => customers(:cameron),
                                        :start_at => "20080801000000",
                                        :end_at =>   "20080802000000")  # available all day
    
    # split appointment, no commit
    job           = jobs(:haircut)
    job_start_at  = "20080801000000"
    job_end_at    = "20080801003000" # 30 minutes
    
    assert_no_difference('Appointment.count') do
      appts         = available_appt.split(job, job_start_at, job_end_at)
    
      # should now have 2 appointments
      assert_equal 2, appts.size
      new_appt      = appts[0]
      end_appt      = appts[1]
    
      # new appointment should have the specified job
      assert_equal job, new_appt.job
    
      # new appointment should match job start, end time
      assert_equal Time.zone.parse(job_start_at), new_appt.start_at
      assert_equal Time.zone.parse(job_end_at), new_appt.end_at

      # end appointment should start when new appointment ends
      assert_equal new_appt.end_at, end_appt.start_at
      assert_equal available_appt.end_at, end_appt.end_at
    end

    assert_difference('Appointment.count', 1) do
      # split, commit appointment
      appts = available_appt.split(job, job_start_at, job_end_at, :commit => 1)
    end
  end
  
  def test_should_schedule_job_at_start_of_available_timeslot
    # create big available timeslot
    available_appt = Appointment.create(:company => companies(:company1), 
                                        :job => jobs(:available),
                                        :resource => resources(:johnny),
                                        :customer => customers(:cameron),
                                        :start_at => "20080801000000",
                                        :end_at =>   "20080802000000")  # available all day
    
    # split appointment
    job           = jobs(:haircut)
    job_start_at  = "20080801002330"
    job_end_at    = "20080802000000" # 30 minutes
      
    assert_no_difference('Appointment.count') do
      appts         = available_appt.split(job, job_start_at, job_end_at)
  
      # should now have 2 appointments
      assert_equal 2, appts.size
      start_appt    = appts[0]
      new_appt      = appts[1]
  
      # new appointment should have the specified job
      assert_equal job, new_appt.job
    
      # start appointment should end when new appointment starts
      assert_equal available_appt.start_at, start_appt.start_at
      assert_equal new_appt.start_at, start_appt.end_at
  
      # new appointment should match job start, end time
      assert_equal Time.zone.parse(job_start_at), new_appt.start_at
      assert_equal Time.zone.parse(job_end_at), new_appt.end_at
    end

    assert_difference('Appointment.count', 1) do
      # split, commit appointment
      appts = available_appt.split(job, job_start_at, job_end_at, :commit => 1)
    end
  end
    
end
