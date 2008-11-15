require 'test/test_helper'

class TimeRangeTest < ActiveSupport::TestCase
  fixtures :resources, :jobs, :companies
  
  def test_time_range
    tomorrow  = (Time.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
    free_time = TimeRange.new(:day => tomorrow,
                              :start_at => "1 pm",
                              :end_at => "3 pm",
                              :resource_id => resources(:johnny).id,
                              :company_id => companies(:company1).id,
                              :customer_id => 0)
    # start_at, end_at times should be adjusted to 'day'    
    assert_equal Chronic.parse("tomorrow 1 pm"), free_time.start_at
    assert_equal Chronic.parse("tomorrow 3 pm"), free_time.end_at
  end


end