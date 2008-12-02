require 'test/test_helper'

class AppointmentRequestTest < ActiveSupport::TestCase
  
  def test_should_find_free_time
    # create free time from 8 am to noon
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    free      = Factory(:free_service, :company => company)
    haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
    anyone    = Person.anyone
    
    start_at  = Time.now.beginning_of_day + 8.hours
    end_at    = start_at + 4.hours
    appt      = AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
    assert appt.valid?
    
    # create appointment request for a specific service but no specific resource
    request   = AppointmentRequest.new(:start_at => start_at + 2.hours, :end_at => end_at + 2.hours, :company => company, :service => haircut, :resource => anyone, :customer_id => 0)
    
    # should find no free appointments
    appts     = request.find_free_appointments
    assert_equal [], appts
    
    # create appointment request for a specific service with a specific resource, with range from 10 am to 2 pm
    request   = AppointmentRequest.new(:start_at => start_at + 2.hours, :end_at => end_at + 2.hours, :company => company, :service => haircut, :resource => johnny, :customer_id => 0)

    # should find no free appointments
    appts     = request.find_free_appointments
    assert_equal [], appts
    
    # create person skill
    haircut.resources.push(johnny)
    
    # should find free appointment created above
    appts     = request.find_free_appointments
    assert_equal [appt], appts
    
    # should find all free time slots within the appointment request range
    timeslots = request.find_free_timeslots
    assert_equal 4, timeslots.size
    assert_equal appt, timeslots[0].appointment
    assert_equal 30, timeslots[0].duration
    assert_equal Chronic.parse("today 10:00 am"), timeslots[0].start_at
    assert_equal Chronic.parse("today 10:30 am"), timeslots[0].end_at
    assert_equal 30, timeslots[1].duration
    assert_equal Chronic.parse("today 10:30 am"), timeslots[1].start_at
    assert_equal Chronic.parse("today 11:00 am"), timeslots[1].end_at
    assert_equal 30, timeslots[2].duration
    assert_equal Chronic.parse("today 11:00 am"), timeslots[2].start_at
    assert_equal Chronic.parse("today 11:30 am"), timeslots[2].end_at
    assert_equal 30, timeslots[3].duration
    assert_equal Chronic.parse("today 11:30 am"), timeslots[3].start_at
    assert_equal Chronic.parse("today 12:00 pm"), timeslots[3].end_at

    # should find 1 timeslot
    timeslots = request.find_free_timeslots(:limit => 1)
    assert_equal 1, timeslots.size
    assert_equal 30, timeslots[0].duration
    assert_equal Chronic.parse("today 10:00 am"), timeslots[0].start_at
    assert_equal Chronic.parse("today 10:30 am"), timeslots[0].end_at
    
    # create appointment object, with range from 7 am to 5 pm
    request   = AppointmentRequest.new(:start_at => start_at - 1.hour, :end_at => end_at + 5.hours, :company => company, :service => haircut, :resource => johnny, :customer_id => 0)
    
    # find all free time slots within the time range
    timeslots = request.find_free_timeslots
  
    # should find 8 time slots of 30 minutes each, with start times incremented by 30 minutes
    assert_equal 8, timeslots.size
    assert_equal 30, timeslots[0].duration
    assert_equal Chronic.parse("today 8:00 am"), timeslots[0].start_at
    assert_equal Chronic.parse("today 8:30 am"), timeslots[0].end_at
      
    # create appointment object, with range from noon to 5 pm
    request   = AppointmentRequest.new(:start_at => start_at + 4.hours, :end_at => end_at + 5.hours, :company => company, :service => haircut, :resource => johnny, :customer_id => 0)
    
    # find all free time slots within the time range
    timeslots = request.find_free_timeslots
    
    # should find 0 timeslots
    assert_equal 0, timeslots.size
  end
  
end