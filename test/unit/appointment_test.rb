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
    # appts = Appointment.span(Chronic.parse("today 2 pm").utc, Chronic.parse("today 2:30 pm").utc)
    # assert_equal 1, appts.size
    
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
    
    assert_equal "", appt.errors.full_messages
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
      new_appt      = appts[1]
      end_appt      = appts[2]
    
      # new appointment should have the specified job
      assert_equal job, new_appt.job
    
      # start appointment should end when new appointment starts
      assert_equal available_appt.start_at, start_appt.start_at
      assert_equal new_appt.start_at, start_appt.end_at
      assert_equal 'free', start_appt.mark_as
      
      # new appointment should match job start, end times
      assert_equal Time.zone.parse(job_start_at), new_appt.start_at
      assert_equal Time.zone.parse(job_end_at), new_appt.end_at
      # new appointment should be marked as work
      assert_equal 'work', new_appt.mark_as
    
      # end appointment should start when new appointment ends
      assert_equal new_appt.end_at, end_appt.start_at
      assert_equal available_appt.end_at, end_appt.end_at
      assert_equal 'free', end_appt.mark_as
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
    job_start_at  = "20080801002330"
    job_end_at    = "20080802000000" # 30 minutes
      
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
  
  def test_should_find_free_timeslots
    # create free time from 8 am to noon
    company1  = companies(:company1)
    johnny    = resources(:johnny)
    start_at  = Time.now.beginning_of_day + 8.hours
    end_at    = start_at + 4.hours
    appt      = Appointment.create_free_time(company1, johnny, start_at, end_at)
    
    # create appointment object, with range from 10 am to 2 pm
    job       = jobs(:haircut)
    range     = Appointment.new(:start_at => start_at + 2.hours, :end_at => end_at + 2.hours, :company => company1, :job => job, :resource => johnny, :customer_id => 0)
    
    # find all free time slots within the time range
    free_time_collection = range.find_free_time
    
    # should find 4 slots of 30 minutes each, with start times incremented by 30 minutes, and each timeslot should be marked as 'free'
    assert_equal 4, free_time_collection.size
    assert_equal 30, free_time_collection[0].duration
    assert_equal Chronic.parse("today 10:00 am"), free_time_collection[0].start_at
    assert_equal 'free', free_time_collection[0].mark_as
    assert_equal 30, free_time_collection[1].duration
    assert_equal Chronic.parse("today 10:30 am"), free_time_collection[1].start_at
    assert_equal 'free', free_time_collection[1].mark_as
    assert_equal 30, free_time_collection[2].duration
    assert_equal Chronic.parse("today 11 am"), free_time_collection[2].start_at
    assert_equal 'free', free_time_collection[2].mark_as
    assert_equal 30, free_time_collection[3].duration
    assert_equal Chronic.parse("today 11:30 am"), free_time_collection[3].start_at
    assert_equal 'free', free_time_collection[3].mark_as
    
    # should find 1 item in free time collection, each timeslot should be marked as 'free'
    free_time_collection = range.find_free_time(:limit => 1)
    assert_equal 1, free_time_collection.size
    assert_equal 30, free_time_collection[0].duration
    assert_equal Chronic.parse("today 10:00 am"), free_time_collection[0].start_at
    assert_equal 'free', free_time_collection[0].mark_as

    # create appointment object, with range from 7 am to 5 pm
    job       = jobs(:haircut)
    range     = Appointment.new(:start_at => start_at - 1.hour, :end_at => end_at + 5.hours, :company => company1, :job => job, :resource => johnny, :customer_id => 0)
    
    # find all free time slots within the time range
    free_time_collection = range.find_free_time

    # should find 8 slots of 30 minutes each, with start times incremented by 30 minutes, each timeslot should be marked as 'free'
    assert_equal 8, free_time_collection.size
    assert_equal 30, free_time_collection[0].duration
    assert_equal Chronic.parse("today 8:00 am"), free_time_collection[0].start_at
    assert_equal 'free', free_time_collection[0].mark_as

    # find all free time slots within the range, with the job_id set
    free_time_collection = range.find_free_time(:job => job)

    # should find 8 slots of 30 minutes each, with start times incremented by 30 minutes, each timeslot should be marked as 'work'
    assert_equal 8, free_time_collection.size
    assert_equal 30, free_time_collection[0].duration
    assert_equal Chronic.parse("today 8:00 am"), free_time_collection[0].start_at
    assert_equal job, free_time_collection[0].job
    assert_equal 'work', free_time_collection[0].mark_as
    
    # create appointment object, with range from noon to 5 pm
    job       = jobs(:haircut)
    range     = Appointment.new(:start_at => start_at + 4.hours, :end_at => end_at + 5.hours, :company => company1, :job => job, :resource => johnny, :customer_id => 0)
    
    # find all free time slots within the time range
    free_time_collection = range.find_free_time
    
    # should find 0 items in free time collection
    assert_equal 0, free_time_collection.size
  end
  
end
