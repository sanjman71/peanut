require 'test/test_helper'

class DateRangeTest < ActiveSupport::TestCase

  context 'today' do
    setup do 
      @daterange = DateRange.parse_when('today')
      assert_valid @daterange
    end
    
    should 'have days count of 1' do
      assert_equal 1, @daterange.days
    end
    
    should 'have start day of today' do
      assert_equal Time.now.beginning_of_day, @daterange.start_at
    end
    
    should 'be named Today' do
      assert_equal 'Today', @daterange.name
    end
  end
  
  context 'tomorrow' do
    setup do
      @daterange = DateRange.parse_when('tomorrow')
      assert_valid @daterange
    end

    should 'have days count of 1' do
      assert_equal 1, @daterange.days
    end

    should 'have start day of tomorrow' do
      assert_equal Time.now.beginning_of_day + 1.day, @daterange.start_at
    end

    should 'be named Tomorrow' do
      assert_equal 'Tomorrow', @daterange.name
    end
  end

  context 'this week' do
    setup do
      @daterange = DateRange.parse_when('this week')
      assert_valid @daterange
      # sunday is day 0, saturday is day 6
      @days_left_in_week = Hash[0=>1, 1=>7, 2=>6, 3=>5, 4=>4, 5=>3, 6=>2]
    end

    should 'have days count based on current day of week' do
      assert_equal @days_left_in_week[Time.now.wday], @daterange.days
    end

    should 'have start day of today' do
      assert_equal Time.now.beginning_of_day, @daterange.start_at
    end

    should 'be named This Week' do
      assert_equal 'This Week', @daterange.name
    end
  end

  context 'next week' do
    setup do
      @daterange = DateRange.parse_when('next week')
      assert_valid @daterange
    end

    should 'have 7 days in the date range' do
      assert_equal 7, @daterange.days
    end

    should 'have start day of monday' do
      assert_equal 1, @daterange.start_at.wday
    end
    
    should 'be named Next Week' do
      assert_equal 'Next Week', @daterange.name
    end
  end

  context 'next 2 weeks' do
    setup do
      @daterange = DateRange.parse_when('next 2 weeks')
      assert_valid @daterange
    end

    should 'have 14 days in the date range' do
      assert_equal 14, @daterange.days
    end

    should 'have start day as today' do
      assert_equal Time.now.beginning_of_day, @daterange.start_at
    end

    should 'be named Next 2 Weeks' do
      assert_equal 'Next 2 Weeks', @daterange.name
    end
  end

  context 'next 2 weeks that ends on a sunday' do
    setup do
      @daterange = DateRange.parse_when('next 2 weeks', :end_on => 0)
      assert_valid @daterange
      # calculate days to add based on current day and end on day
      @days_to_add = Hash[0=>0, 1=>6, 2=>5, 3=>4, 4=>3, 5=>2, 6=>1][Date.today.wday]
    end
    
    should 'have start day of today' do
      assert_equal Time.now.beginning_of_day, @daterange.start_at
    end
    
    should "have last day a sunday" do
      assert_equal 0, @daterange.end_at.wday
    end
    
    should 'have the days count adjusted to end day' do
      assert_equal 14 + @days_to_add, @daterange.days
    end
    
    should 'be named Next 2 Weeks' do
      assert_equal 'Next 2 Weeks', @daterange.name
    end
  end
  
  context 'next 6 weeks' do
    setup do
      @daterange = DateRange.parse_when('next 6 weeks')
      assert_valid @daterange
    end
    
    should 'have 42 days in the date range' do
      assert_equal 42, @daterange.days
    end

    should 'have start day as today' do
      assert_equal Time.now.beginning_of_day, @daterange.start_at
    end
    
    should 'be named Next 6 Weeks' do
      assert_equal 'Next 6 Weeks', @daterange.name
    end
  end
  
  context 'past week' do
    setup do
      @daterange = DateRange.parse_when('past week')
      assert_valid @daterange
    end

    should 'have 7 days in the date range' do
      assert_equal 7, @daterange.days
    end

    should 'be named Past Week' do
      assert_equal 'Past Week', @daterange.name
    end
  end
  
  context 'bogus when' do
    setup do
      @daterange = DateRange.parse_when('bogus')
    end
    
    should 'not be valid' do
      assert !@daterange.valid?
    end
    
    should 'have errors' do
      assert_match /When is invalid/, @daterange.errors[:base]
    end
  end
  
  context 'date range inclusive' do
    setup do
      @daterange = DateRange.parse_range('20090101', '20090107')
      assert_valid @daterange
    end

    should 'have 7 days in the date range' do
      assert_equal 7, @daterange.days
    end
    
    should 'have start day as Jan 1 2009' do
      assert_equal "20090101", @daterange.start_at.to_s(:appt_schedule_day)
    end

    should 'have end day as Jan 8 2009' do
      assert_equal "20090107", @daterange.end_at.to_s(:appt_schedule_day)
    end
    
    should 'have name with start and end dates' do
      assert_equal 'Jan 01 2009 - Jan 07 2009', @daterange.name
    end
  end

  context 'date range exclusive' do
    setup do
      @daterange = DateRange.parse_range('20090101', '20090107', :inclusive => false)
      assert_valid @daterange
    end

    should 'have 6 days in the date range' do
      assert_equal 6, @daterange.days
    end

    should 'have name with start and end dates' do
      assert_equal 'Jan 01 2009 - Jan 07 2009', @daterange.name
    end
  end
  
end