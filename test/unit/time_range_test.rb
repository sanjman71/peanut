require 'test/test_helper'
require 'test/factories'

class TimeRangeTest < ActiveSupport::TestCase
  
  def test_should_create_time_range_using_chronic_string
    @tomorrow    = (Time.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
    @time_range  = TimeRange.new(:day => @tomorrow, :start_at => "1 pm", :end_at => "3 pm")
  
    # start_at, end_at times should be adjusted to tomorrow
    assert_equal Chronic.parse("tomorrow 1 pm"), @time_range.start_at
    assert_equal Chronic.parse("tomorrow 3 pm"), @time_range.end_at
    
    # duration should be 120 minutes
    assert_equal 120, @time_range.duration
  end
  
  def test_should_create_default_time_range_of_all_day_today
    @time_range  = TimeRange.new(:day => Date.today.to_s(:appt_schedule_day))

    # should default to all day today
    assert_equal Chronic.parse("yesterday midnight"), @time_range.start_at
    assert_equal Chronic.parse("today midnight"), @time_range.end_at
  end

  def test_should_create_time_range_using_military_notation
    @time_range  = TimeRange.new(:day => Date.today.to_s(:appt_schedule_day), :start_at => "0300", :end_at => "0500")
    
    # start_at, end_at times should be adjusted to tomorrow
    assert_equal Chronic.parse("today 3 am"), @time_range.start_at
    assert_equal Chronic.parse("today 5 am"), @time_range.end_at
    
    # duration should be 120 minutes
    assert_equal 120, @time_range.duration

    @time_range  = TimeRange.new(:day => Date.today.to_s(:appt_schedule_day), :start_at => "1500", :end_at => "1800")
    
    # start_at, end_at times should be adjusted to tomorrow
    assert_equal Chronic.parse("today 3 pm"), @time_range.start_at
    assert_equal Chronic.parse("today 6 pm"), @time_range.end_at
    
    # duration should be 180 minutes
    assert_equal 180, @time_range.duration
  end
end