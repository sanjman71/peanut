require 'test/test_helper'

class DateRangeTest < ActiveSupport::TestCase

  def test_today
    daterange = DateRange.new(:when => 'today')
    assert_equal 1, daterange.days
  end

  def test_tomorrow
    daterange = DateRange.new(:when => 'tomorrow')
    assert_equal 1, daterange.days
  end
  
  def test_this_week
    daterange = DateRange.new(:when => 'next week')
    assert_equal 7, daterange.days
  end

  def test_next_two_weeks
    daterange = DateRange.new(:when => 'next 2 weeks')
    assert_equal 14, daterange.days
  end
end