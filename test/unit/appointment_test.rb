require 'test/test_helper'
require 'test/factories'

class AppointmentTest < ActiveSupport::TestCase
  
  # shoulda
  should_require_attributes :company_id
  should_require_attributes :service_id
  should_require_attributes :customer_id
  should_require_attributes :resource_id
  should_require_attributes :resource_type
  should_require_attributes :start_at
  should_require_attributes :end_at
  should_allow_values_for   :mark_as, "free", "busy", "work", "wait"
    
  def test_time_of_day
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
    customer  = Factory(:customer)

    assert_difference('Appointment.count') do
      # create appointment at 2 pm
      appt = Appointment.create(:company => company,
                                :service => haircut,
                                :resource => johnny,
                                :customer => customer,
                                :start_at_string => "today 2 pm")

      assert appt.valid?
      assert_equal '', appt.when
      
      # check time of day values, which are utc
      assert_equal '', appt.time
      assert_equal (14*3600) - Time.zone.utc_offset, appt.time_start_at
      assert_equal (14*3600) + (30*60) - Time.zone.utc_offset, appt.time_end_at
      
      # test time searches, only afternoon and anytime should match
      assert_equal [], Appointment.time_overlap(Appointment.time_range("morning"))
      assert_equal [appt], Appointment.time_overlap(Appointment.time_range("afternoon"))
      assert_equal [], Appointment.time_overlap(Appointment.time_range("evening"))
      assert_equal [appt], Appointment.time_overlap(Appointment.time_range("anytime"))
      assert_equal [], Appointment.time_overlap(Appointment.time_range("bogus"))
    end
  end
  
  def test_overlap
    # clear database
    Appointment.delete_all
    
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
    customer  = Factory(:customer)
    
    # create appointment
    appt = Appointment.create(:company => company,
                              :service => haircut,
                              :resource => johnny,
                              :customer => customer,
                              :start_at_string => "today 2 pm")
    assert appt.valid?
    assert_equal '', appt.when
    assert_equal Chronic.parse("today 2 pm"), appt.start_at
    assert_equal Chronic.parse("today 2:30 pm"), appt.end_at

    # test appointment that matches exact start and end times
    appts = Appointment.overlap(Chronic.parse("today 2 pm").utc, Chronic.parse("today 2:30 pm").utc)
    assert_equal 1, appts.size
    assert_equal [appt], appts
    
    # test appointment that ends at start time
    appts = Appointment.overlap(Chronic.parse("today 1 pm").utc, Chronic.parse("today 2 pm").utc)
    assert_equal 0, appts.size

    # test appointment that starts at end time
    appts = Appointment.overlap(Chronic.parse("today 2:30 pm").utc, Chronic.parse("today 3 pm").utc)
    assert_equal 0, appts.size

    # test range that overlaps appointment start time
    appts = Appointment.overlap(Chronic.parse("today 1:30 pm").utc, Chronic.parse("today 2:15 pm").utc)
    assert_equal 1, appts.size
    assert_equal [appt], appts

    # test range that overlaps appointment end time
    appts = Appointment.overlap(Chronic.parse("today 2:15 pm").utc, Chronic.parse("today 2:45 pm").utc)
    assert_equal 1, appts.size
    assert_equal [appt], appts
    
    # test range that envelopes the appointment
    appts = Appointment.overlap(Chronic.parse("today 1:30 pm").utc, Chronic.parse("today 3 pm").utc)
    assert_equal 1, appts.size
    assert_equal [appt], appts

    # test range that is within the appointment
    appts = Appointment.overlap(Chronic.parse("today 2:05 pm").utc, Chronic.parse("today 2:15 pm").utc)
    assert_equal 1, appts.size
    assert_equal [appt], appts
  end
  
  def test_should_set_end_at_on_new_appointment
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
    customer  = Factory(:customer)
    
    assert_difference('Appointment.count') do
      appt = Appointment.create(:company => company,
                                :service => haircut,
                                :resource => johnny,
                                :customer => customer,
                                :start_at_string => "today 2 pm")
      assert appt.valid?
      assert_equal Chronic.parse("today 2 pm"), appt.start_at
      assert_equal Chronic.parse("today 2:30 pm").to_i, appt.end_at.to_i
    end
  end
  
  def test_should_not_allow_when_start_at_is_same_as_end_at
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company, :price => 1.00)
    customer  = Factory(:customer)
    
    assert_no_difference('Appointment.count') do
      appt = Appointment.create(:company => company, 
                                :service => free,
                                :resource => johnny,
                                :customer => customer,
                                :start_at => "20080802000000",
                                :end_at =>   "20080802000000")
      assert !appt.valid?
      assert_match /Appointment start time/, appt.errors[:base]
    end
  end

  def test_should_not_allow_start_at_after_end_at
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company, :price => 1.00)
    customer  = Factory(:customer)
    
    assert_no_difference('Appointment.count') do
      appt = Appointment.create(:company => company, 
                                :service => free,
                                :resource => johnny,
                                :customer => customer,
                                :start_at => "20080802000000",
                                :end_at =>   "20080801010000")
      assert !appt.valid?
      assert_match /Appointment start time/, appt.errors[:base]
    end
  end
  
  def test_should_set_duration
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company, :price => 1.00)
    customer  = Factory(:customer)
    
    assert_difference('Appointment.count') do
      appt = Appointment.create(:company => company, 
                                :service => free,
                                :resource => johnny,
                                :customer => customer,
                                :start_at => "20080801000000",
                                :end_at =>   "20080801010000") # 1 hour
      assert appt.valid?
      assert_equal 60, appt.duration
    end
  end
  
  def test_should_create_and_search_waitlist
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
    customer  = Factory(:customer)
    
    # create waitlist appointment
    wait      = Appointment.create(:company => company,
                                   :mark_as => Appointment::WAIT,
                                   :service => haircut,
                                   :resource => johnny,
                                   :customer => customer,
                                   :when => "this week",
                                   :time => "morning")
    assert_valid wait
    wait.reload
    # appointment should be on waitlist
    assert wait.waitlist?
    assert_equal Appointment::WAIT, wait.mark_as
    # appointment should have a non-zero confirmation code
    assert_not_equal Appointment::CONFIRMATION_CODE_ZERO, wait.confirmation_code
    assert_equal haircut, wait.service
    assert_equal johnny, wait.resource
    assert_equal "upcoming", wait.state
    
    # assert_equal "", appt.start_at
    # assert_equal "", appt.end_at
    # time range should be entire day
    # assert_equal 0 - Time.zone.utc_offset, appt.time_start_at
    # assert_equal 24*3600 - Time.zone.utc_offset, appt.time_end_at
    
    # should find wait appointment on a blanket search
    assert_equal [wait], Appointment.wait
    
    # should find wait appointment on a morning search 
    assert_equal [wait], Appointment.wait.time_overlap(Appointment.time_range('morning'))

    # should find wait appointment on an anytiem search 
    assert_equal [wait], Appointment.wait.time_overlap(Appointment.time_range('anytime'))

    # should find no waitlist appointment on an afternoon search 
    assert_equal [], Appointment.wait.time_overlap(Appointment.time_range('afternoon'))

    # should find no waitlist appointment on an evening search 
    assert_equal [], Appointment.wait.time_overlap(Appointment.time_range('evening'))

    # should find no waitlist appointment on an invalid search 
    assert_equal [], Appointment.wait.time_overlap(Appointment.time_range('bogus'))
    
    # create free time from 8 am to noon
    free      = Factory(:free_service, :company => company)
    start_at  = wait.start_at.beginning_of_day + 8.hours
    end_at    = start_at + 4.hours
    appt      = AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
    assert appt.valid?
    
    # should find waitlist overlap
    assert_equal [wait], appt.waitlist

    # create free time from noon to 5 pm
    start_at  = wait.start_at.beginning_of_day + 12.hours
    end_at    = start_at + 4.hours
    appt      = AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
    assert appt.valid?
    
    # should find no waitlist overlap
    assert_equal [], appt.waitlist

    # create free time from 1 am to 8 am
    start_at  = wait.start_at.beginning_of_day + 1.hour
    end_at    = start_at + 7.hours
    appt      = AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
    assert appt.valid?

    # should find no waitlist overlap
    assert_equal [], appt.waitlist
  end

  def test_should_validate_when_attribute
    appt = Appointment.new(:when => 'bogus')
    assert !appt.valid?
    # should have an error for the when attribute
    assert_equal "When is invalid", appt.errors[:base]
  end

  def test_should_validate_time_attribute
    appt = Appointment.new(:time => 'bogus')
    assert !appt.valid?
    # should have an error for the time attribute
    assert_equal "Time is invalid", appt.errors[:base]
  end
  
  def test_should_validate_time_range_attribute
    today = Time.now.to_s(:appt_schedule_day) # e.g. 20081201
    appt  = Appointment.new(:time_range => {:day => today, :start_at => "1 pm", :end_at => "3 pm"})
    assert_equal Chronic.parse("today 1 pm"), appt.start_at
    assert_equal Chronic.parse("today 3 pm"), appt.end_at
  end
  
  def test_should_build_customer_association
    company = Factory(:company)
    johnny  = Factory(:person, :name => "Johnny", :companies => [company])
    haircut = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
    
    # should create a new customer when building the new appointment
    assert_difference('Customer.count', 1) do
      appt = Appointment.new(:company => company, 
                             :service => haircut,
                             :resource => johnny,
                             :customer_attributes => {"name" => "Customer 1", "email" => "customer1@peanut.com", "phone" => "4085551212"},
                             :start_at_string => "today 2 pm")
    
      assert appt.valid?
    end
    
    # should use the existing customer when building the new appointment
    assert_no_difference('Customer.count') do
      appt = Appointment.new(:company => company, 
                             :service => haircut,
                             :resource => johnny,
                             :customer_attributes => {"name" => "Customer 1", "email" => "customer1@peanut.com", "phone" => "4085551212"},
                             :start_at_string => "today 2 pm")
    
      assert appt.valid?
    end
  end  
        
  def test_confirmation_code
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company, :price => 1.00)
    customer  = Factory(:customer)
    
    appt = Appointment.create(:company => company, 
                              :service => free,
                              :resource => johnny,
                              :customer => customer,
                              :start_at => "20080801000000",
                              :end_at =>   "20080801010000") # 1 hour
    assert appt.valid?
    
    # confirmation code should be 5 characters
    assert_equal 5, appt.confirmation_code.size
    assert_match /([A-Z]|[0-9])+/, appt.confirmation_code

    # create another appointment
    appt2 = Appointment.create(:company => company, 
                               :service => free,
                               :resource => johnny,
                               :customer => customer,
                               :start_at => "20080901000000",
                               :end_at =>   "20080901010000") # 1 hour
    assert appt2.valid?

    # confirmation code should be 5 characters
    assert_equal 5, appt2.confirmation_code.size
    assert_match /([A-Z]|[0-9])+/, appt2.confirmation_code
    # confirmation code should the same for free appointments
    assert_equal appt.confirmation_code, appt2.confirmation_code
  end
  
  def test_should_narrow_by_morning
    # build appointment from 5:30am - 12:30pm
    appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
    
    # request morning appointments, narraw from 8am - 12pm
    appointment.narrow_by_time_of_day!('morning')
    assert_equal  Time.now.beginning_of_day + 8.hours, appointment.start_at
    assert_equal  Time.now.beginning_of_day + 12.hours, appointment.end_at
  end
  
  def test_should_narrow_by_afternoon_to_empty
    # build appointment from 5:30am - 12pm
    appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
    
    # request afternoon appointments, narrow to empty
    appointment.narrow_by_time_of_day!('afternoon')
    assert_equal nil, appointment.start_at
    assert_equal nil, appointment.end_at
    assert_equal 0, appointment.duration

    # build appointment from 5:30am - 11:30pm
    appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 11:30 am"))
    
    # request afternoon appointments, narrow to empty
    appointment.narrow_by_time_of_day!('afternoon')
    assert_equal nil, appointment.start_at
    assert_equal nil, appointment.end_at
    assert_equal 0, appointment.duration
  end

  def test_should_narrow_by_evening_to_empty
    # build appointment from 5:30am - 12pm
    appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
    
    # request evening appointments, narrow to empty
    appointment.narrow_by_time_of_day!('evening')
    assert_equal nil, appointment.start_at
    assert_equal nil, appointment.end_at
    assert_equal 0, appointment.duration
  end

  def test_narrow_by_anytime
    # build appointment from 5:30am - 12pm
    appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
    
    # request anytime appointments
    appointment.narrow_by_time_of_day!('anytime')
    assert_equal  Time.now.beginning_of_day + 5.hours + 30.minutes, appointment.start_at
    assert_equal  Time.now.beginning_of_day + 12.hours, appointment.end_at
  end
  
  def test_should_narrow_by_bogus_to_empty
    # build appointment from 5:30am - 12pm
    appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
    
    # request an invalid time of day, narrow to empty
    appointment.narrow_by_time_of_day!('bogus')
    assert_equal nil, appointment.start_at
    assert_equal nil, appointment.end_at
  end
  
end
