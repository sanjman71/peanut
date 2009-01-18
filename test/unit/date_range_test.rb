require 'test/test_helper'

class DateRangeTest < ActiveSupport::TestCase

  context 'parse today' do
    setup do 
      @daterange = DateRange.parse_when('today')
    end
    
    should 'have no errors' do
      assert !@daterange.errors
    end
    
    should 'have days count of 1' do
      assert_equal 1, @daterange.days
    end
  end
  
  context 'parse tomorrow' do
    setup do
      @daterange = DateRange.parse_when('tomorrow')
    end

    should 'have no errors' do
      assert !@daterange.errors
    end

    should 'have days count of 1' do
      assert_equal 1, @daterange.days
    end
  end

  context 'this week' do
    setup do
      @daterange = DateRange.parse_when('this week')
      # sunday is day 0, saturday is day 6
      @days_left_in_week = Hash[0=>1, 1=>7, 2=>6, 3=>5, 4=>4, 5=>3, 6=>2]
    end

    should 'have no errors' do
      assert !@daterange.errors
    end

    should 'have days count based on current day of week' do
      assert_equal @days_left_in_week[Time.now.wday], @daterange.days
    end
  end

  context 'next week' do
    setup do
      @daterange = DateRange.parse_when('next week')
    end

    should 'have no errors' do
      assert !@daterange.errors
    end

    should 'have days count of 7' do
      assert_equal 7, @daterange.days
    end
  end

  context 'next 2 weeks' do
    setup do
      @daterange = DateRange.parse_when('next 2 weeks')
    end

    should 'have no errors' do
      assert !@daterange.errors
    end

    should 'have days count of 14' do
      assert_equal 14, @daterange.days
    end
  end
  
  context 'past week' do
    setup do
      @daterange = DateRange.parse_when('past week')
    end

    should 'have no errors' do
      assert !@daterange.errors
    end

    should 'have days count of 7' do
      assert_equal 7, @daterange.days
    end
  end
  
end