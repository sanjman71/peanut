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
  should_allow_values_for :mark_as, "free", "busy"
  
  def test_span
    # clear database
    Appointment.delete_all
    
    # create appointment
    appt = Appointment.create(:company => companies(:company1),
                              :job => jobs(:haircut),
                              :resource => resources(:johnny),
                              :customer => customers(:cameron),
                              :start_at_string => "today 2 pm")
    assert appt.valid?
    assert_equal Chronic.parse("today 2 pm"), appt.start_at
    assert_equal Chronic.parse("today 2:30 pm"), appt.end_at

    # test appointment that matches exact start and end times
    appts = Appointment.span(Chronic.parse("today 2 pm").utc, Chronic.parse("today 2:30 pm").utc)
    assert_equal 1, appts.size
    
    # test appointment that ends at start time
    appts = Appointment.span(Chronic.parse("today 1 pm").utc, Chronic.parse("today 2 pm").utc)
    assert_equal 0, appts.size

    # test appointment that starts at end time
    appts = Appointment.span(Chronic.parse("today 2:30 pm").utc, Chronic.parse("today 3 pm").utc)
    assert_equal 0, appts.size

    # test span that overlaps appointment start time
    appts = Appointment.span(Chronic.parse("today 1:30 pm").utc, Chronic.parse("today 2:15 pm").utc)
    assert_equal 1, appts.size
    assert_equal appt, appts.first

    # test span that overlaps appointment end time
    appts = Appointment.span(Chronic.parse("today 2:15 pm").utc, Chronic.parse("today 2:45 pm").utc)
    assert_equal 1, appts.size
    assert_equal appt, appts.first
    
    # test span that envelopes the appointment
    appts = Appointment.span(Chronic.parse("today 1:30 pm").utc, Chronic.parse("today 3 pm").utc)
    assert_equal 1, appts.size
    assert_equal appt, appts.first

    # test span that is within the appointment
    appts = Appointment.span(Chronic.parse("today 2:05 pm").utc, Chronic.parse("today 2:15 pm").utc)
    assert_equal 1, appts.size
    assert_equal appt, appts.first
  end
  
  def test_should_set_end_at_on_new_appointment
    assert_difference('Appointment.count') do
      appt = Appointment.create(:company => companies(:company1),
                                :job => jobs(:haircut),
                                :resource => resources(:johnny),
                                :customer => customers(:cameron),
                                :start_at_string => "today 2 pm")
      assert appt.valid?
      assert_equal Chronic.parse("today 2 pm"), appt.start_at
      assert_equal Chronic.parse("today 2:30 pm").to_i, appt.end_at.to_i
    end
  end
  
  def test_should_not_allow_when_start_at_is_same_as_end_at
    appt = Appointment.create(:company => companies(:company1), 
                              :job => jobs(:available),
                              :resource => resources(:johnny),
                              :customer => customers(:cameron),
                              :start_at => "20080802000000",
                              :end_at =>   "20080802000000")
    assert !appt.valid?
    assert_match /Appointment start time/, appt.errors[:base]
  end

  def test_should_not_allow_start_at_after_end_at
    assert_no_difference('Appointment.count') do
      appt = Appointment.create(:company => companies(:company1), 
                                :job => jobs(:available),
                                :resource => resources(:johnny),
                                :customer => customers(:cameron),
                                :start_at => "20080802000000",
                                :end_at =>   "20080801010000")
      assert !appt.valid?
      assert_match /Appointment start time/, appt.errors[:base]
    end
  end
  
  def test_should_set_duration
    assert_difference('Appointment.count') do
      appt = Appointment.create(:company => companies(:company1), 
                                :job => jobs(:available),
                                :resource => resources(:johnny),
                                :customer => customers(:cameron),
                                :start_at => "20080801000000",
                                :end_at =>   "20080801010000") # 1 hour
      assert appt.valid?
      assert_equal 60, appt.duration
    end
  end
  
  def test_should_validate_when_attribute
    appt = Appointment.new(:when => '')
    assert !appt.valid?
    # should have an error for the when attribute
    assert_equal ["When string is empty"], appt.errors.full_messages.select { |s| s.match(/When/) }
  end
  
  def test_should_validate_time_range_attribute
    today = Time.now.to_s(:appt_schedule_day) # e.g. 20081201
    appt  = Appointment.new(:time_range => {:day => today, :start_at => "1 pm", :end_at => "3 pm"})
    assert_equal Chronic.parse("today 1 pm"), appt.start_at
    assert_equal Chronic.parse("today 3 pm"), appt.end_at
  end
  
  def test_should_build_customer_association
    # should create a new customer when building the new appointment
    assert_difference('Customer.count', 1) do
      appt = Appointment.new(:company => companies(:company1), 
                             :job => jobs(:haircut),
                             :resource => resources(:johnny),
                             :customer_attributes => {"name" => "Customer 1", "email" => "customer1@getfave.com", "phone" => "4085551212"},
                             :start_at_string => "today 2 pm")
    
      assert appt.valid?
    end
    
    # should use the existing customer when building the new appointment
    assert_no_difference('Customer.count') do
      appt = Appointment.new(:company => companies(:company1), 
                             :job => jobs(:haircut),
                             :resource => resources(:johnny),
                             :customer_attributes => {"name" => "Customer 1", "email" => "customer1@getfave.com", "phone" => "4085551212"},
                             :start_at_string => "today 2 pm")
    
      assert appt.valid?
    end
  end
    
  def test_should_schedule_work
    # create big fee timeslot
    free_appointment = Appointment.create(:company => companies(:company1), 
                                          :job => jobs(:available),
                                          :resource => resources(:johnny),
                                          :customer => customers(:cameron),
                                          :start_at => "20080801000000",
                                          :end_at =>   "20080802000000")  # free all day
                                        
    # create new appointment object for a haircut
    job             = jobs(:haircut)
    new_appointment = Appointment.new(:company => companies(:company1),
                                      :job => job,
                                      :resource => resources(:johnny),
                                      :customer => customers(:cameron),
                                      :start_at => "20080801000000",
                                      :duration =>  job.duration)
                                      
    assert new_appointment.valid?
    
    # should be conflicts
    assert new_appointment.conflicts?
    
    assert_difference('Appointment.count', 1) do
      # schedule the work appointment, the free appointment should be split into free/work time
      work_appointment = new_appointment.schedule_work
      assert work_appointment.valid?
    end
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
      appts         = available_appt.split_free_time(job, job_start_at, job_end_at)
    
      # should now have 3 appointments
      assert_equal 3, appts.size
      start_appt    = appts[0]
      work_appt     = appts[1]
      end_appt      = appts[2]
    
      # new appointment should have the specified job
      assert_equal job, work_appt.job
    
      # start appointment should end when new appointment starts
      assert_equal available_appt.start_at, start_appt.start_at
      assert_equal work_appt.start_at, start_appt.end_at
      assert_equal 'free', start_appt.mark_as
      # free time duration should be adjusted
      assert_equal 1440-30, start_appt.duration
      
      # work appointment should match job start, end times
      assert_equal Time.zone.parse(job_start_at), work_appt.start_at
      assert_equal Time.zone.parse(job_end_at), work_appt.end_at
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
      appts = available_appt.split_free_time(job, job_start_at, job_end_at, :commit => 1)
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
      appts         = available_appt.split_free_time(job, job_start_at, job_end_at)
    
      # should now have 2 appointments
      assert_equal 2, appts.size
      new_appt      = appts[0]
      end_appt      = appts[1]
    
      # new appointment should have the specified job
      assert_equal job, new_appt.job
    
      # new appointment should match job start, end time
      assert_equal Time.zone.parse(job_start_at), new_appt.start_at
      assert_equal Time.zone.parse(job_end_at), new_appt.end_at
      # new appointment should be marked as busy
      assert_equal 'busy', new_appt.mark_as

      # end appointment should start when new appointment ends
      assert_equal new_appt.end_at, end_appt.start_at
      assert_equal available_appt.end_at, end_appt.end_at
      assert_equal 'free', end_appt.mark_as
    end

    assert_difference('Appointment.count', 1) do
      # split, commit appointment
      appts = available_appt.split_free_time(job, job_start_at, job_end_at, :commit => 1)
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
    job_start_at  = "20080801002330" # 11:30 pm
    job_end_at    = "20080802000000" # 12:00 am, 30 minutes
      
    assert_no_difference('Appointment.count') do
      appts         = available_appt.split_free_time(job, job_start_at, job_end_at)
  
      # should now have 2 appointments
      assert_equal 2, appts.size
      start_appt    = appts[0]
      new_appt      = appts[1]
  
      # new appointment should have the specified job
      assert_equal job, new_appt.job
    
      # start appointment should end when new appointment starts
      assert_equal available_appt.start_at, start_appt.start_at
      assert_equal new_appt.start_at, start_appt.end_at
      assert_equal 'free', start_appt.mark_as
  
      # new appointment should match job start, end time
      assert_equal Time.zone.parse(job_start_at), new_appt.start_at
      assert_equal Time.zone.parse(job_end_at), new_appt.end_at
      # new appointment should be marked as work
      assert_equal 'work', new_appt.mark_as
    end

    assert_difference('Appointment.count', 1) do
      # split, commit appointment
      appts = available_appt.split_free_time(job, job_start_at, job_end_at, :commit => 1)
    end
  end
    
  def test_should_create_free_time
    # should create free time for the entire day
    company1  = companies(:company1)
    johnny    = resources(:johnny)
    lisa      = resources(:lisa)
    
    start_at  = Time.now.beginning_of_day
    end_at    = start_at + 1.day
    appt      = Appointment.create_free_time(company1, johnny, start_at, end_at)
    assert appt.valid?
    assert_equal 24 * 60, appt.duration
    
    assert_raise TimeslotNotEmpty do
      # should throw error
      Appointment.create_free_time(company1, johnny, start_at, end_at)
    end
    
    # should create free time for another resource
    appt  = Appointment.create_free_time(company1, lisa, start_at, end_at)
    assert appt.valid?
    assert_equal 24 * 60, appt.duration
  end
  
end
