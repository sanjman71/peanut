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
    
    # should 'have start at == beginning of today in utc format' do
    #   assert_equal Time.zone.now.beginning_of_day.utc, @daterange.start_at
    # end
    # 
    # should 'have end at == end of today in utc format' do
    #   assert_equal Time.zone.now.end_of_day.utc, @daterange.end_at
    # end
    
    should 'have start at == beginning of today in local time, expressed in UTC' do
      assert_equal Time.zone.now.beginning_of_day.utc, @daterange.start_at
    end

    should 'have end at == end of today in local time, expressed in UTC' do
      assert_equal Time.zone.now.end_of_day.utc, @daterange.end_at
    end
    
    should 'be named Today' do
      assert_equal 'Today', @daterange.name
    end

    should 'have url param for today' do
      @today = Time.zone.now.to_s(:appt_schedule_day)
      assert_equal "#{@today}..#{@today}", @daterange.to_url_param
      assert_equal @today, @daterange.to_url_param(:for => :start_date)
      assert_equal @today, @daterange.to_url_param(:for => :end_date)
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

    should 'have start at == beginning of tomorrow in utc format' do
      assert_equal Time.zone.now.beginning_of_day.utc + 1.day, @daterange.start_at
    end

    should 'have end at == end of tomorrow in utc format' do
      assert_equal Time.zone.now.end_of_day.utc + 1.day, @daterange.end_at
    end

    should 'be named Tomorrow' do
      assert_equal 'Tomorrow', @daterange.name
    end

    should 'have url param for tomorrow' do
      @tomorrow = (Time.zone.now + 1.day).to_s(:appt_schedule_day)
      assert_equal "#{@tomorrow}..#{@tomorrow}", @daterange.to_url_param
      assert_equal @tomorrow, @daterange.to_url_param(:for => :start_date)
      assert_equal @tomorrow, @daterange.to_url_param(:for => :end_date)
    end
  end

  context 'this week, including today' do
    setup do
      @daterange = DateRange.parse_when('this week', :include => :today)
      assert_valid @daterange
      # sunday is day 0, saturday is day 6
      @days_left_in_week = Hash[0=>1, 1=>7, 2=>6, 3=>5, 4=>4, 5=>3, 6=>2]
      
      # check if including today adds an extra day
      @add_today_day     = Time.zone.now.utc.yday > Time.zone.now.yday ? 1 : 0
    end

    should 'have days count based on current utc time and day of week' do
      assert_equal @days_left_in_week[Time.zone.now.utc.wday] + @add_today_day, @daterange.days
    end

    should 'have start day == beginning of today (adjusting for today) in utc format' do
      assert_equal Time.zone.now.beginning_of_day.utc - @add_today_day.day, @daterange.start_at
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

    should 'have date range of 7 days' do
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

    should 'have date range of 14 days' do
      assert_equal 14, @daterange.days
    end

    should 'have start at == beginning of today in utc format' do
      assert_equal Time.zone.now.beginning_of_day.utc, @daterange.start_at
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
      # 2 weeks starting on Monday (day #1) begins at 00:00 on Monday and ends at 23:59:59 on Sunday night.
      # The days calculation considers this to be Monday morning first thing, so 6 days are added to get to Sunday.
      @days_to_add = Hash[0=>0, 1=>6, 2=>5, 3=>4, 4=>3, 5=>2, 6=>1][Time.zone.now.wday]
    end
    
    should 'have start at == beginning of today in utc format' do
      assert_equal Time.zone.now.beginning_of_day.utc, @daterange.start_at
    end
    
    should "have last day a sunday" do
      assert_equal 0, @daterange.end_at.in_time_zone.wday
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
    
    should 'have date range of 42 days' do
      assert_equal 42, @daterange.days
    end

    should 'have start day == beginning of today in utc format' do
      assert_equal Time.zone.now.beginning_of_day.utc, @daterange.start_at
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

    should 'have end at == end of today in utc format' do
      assert_equal Time.zone.now.end_of_day.utc, @daterange.end_at
    end

    should 'have start at == 1 week ago in utc format' do
      assert_equal Time.zone.now.beginning_of_day.utc - 6.days, @daterange.start_at
    end

    should 'have date range of 7 days' do
      assert_equal 7, @daterange.days
    end

    should 'be named Past Week' do
      assert_equal 'Past Week', @daterange.name
    end
  end
  
  context 'past month' do
    setup do
      @daterange = DateRange.parse_when('past month')
      assert_valid @daterange
      @expected_days_in_range = Hash[1=>31, 2=>31, 3=>28, 4=>31, 5=>30, 6=>31, 7=>30, 8=>31, 9=>31, 10=>30, 11=>31, 12=>30][Time.zone.now.month]
    end
  
    should 'have end at == end of today in utc format' do
      assert_equal Time.zone.now.end_of_day.utc, @daterange.end_at
    end

    should 'have start at == 1 month ago in utc format' do
      assert_equal Time.zone.now.beginning_of_day.utc - 1.month + 1.day, @daterange.start_at
    end

    should "have date range of #{@expected_days_in_range} days" do
      assert_equal @expected_days_in_range, @daterange.days
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
  
  context 'date range with inclusive dates' do
    setup do
      @daterange = DateRange.parse_range('20090101', '20090107')
      assert_valid @daterange
    end

    should 'have date range of 7 days' do
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
    
    should 'have url param 20090101..20090107' do
      assert_equal "20090101..20090107", @daterange.to_url_param
      assert_equal "20090101", @daterange.to_url_param(:for => :start_date)
      assert_equal "20090107", @daterange.to_url_param(:for => :end_date)
    end
  end

  context 'date range with exclusive dates' do
    setup do
      @daterange = DateRange.parse_range('20090101', '20090107', :inclusive => false)
      assert_valid @daterange
    end

    should 'have date range of 6 days' do
      assert_equal 6, @daterange.days
    end

    should 'have name with start and end dates' do
      assert_equal 'Jan 01 2009 - Jan 07 2009', @daterange.name
    end

    should 'have url param 20090101..20090107' do
      assert_equal "20090101..20090107", @daterange.to_url_param
      assert_equal "20090101", @daterange.to_url_param(:for => :start_date)
      assert_equal "20090107", @daterange.to_url_param(:for => :end_date)
    end
  end
  
end