require 'test/test_helper'

class DateRangeTest < ActiveSupport::TestCase

  def test_today
    daterange = DateRange.new('today')
    assert_equal 1, daterange.days
  end

  def test_tomorrow
    daterange = DateRange.new('tomorrow')
    assert_equal 1, daterange.days
  end
  
  def test_this_week
    daterange = DateRange.new('next week')
    assert_equal 7, daterange.days
  end

  def test_next_two_weeks
    daterange = DateRange.new('next 2 weeks')
    assert_equal 14, daterange.days
  end
end