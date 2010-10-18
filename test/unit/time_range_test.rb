require 'test_helper'

class TimeRangeTest < ActiveSupport::TestCase
  
  def setup
    # Time.zone = "Eastern Time (US & Canada)"
    @today    = Time.now.to_s(:appt_schedule_day)
    @tomorrow = (Time.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
  end

  context "time range created with ampm notation" do
    setup do
      @time_range  = TimeRange.new(:day => @tomorrow, :start_at => "1 pm", :end_at => "3 pm")
    end
  
    should "start tomorrow at 1 pm local time" do
      assert_equal @tomorrow, @time_range.start_at.in_time_zone.to_s(:appt_schedule_day)
      assert_equal 13, @time_range.start_at.in_time_zone.hour
    end
  
    should "end tomorrow at 3 pm local time" do
      assert_equal @tomorrow, @time_range.start_at.in_time_zone.to_s(:appt_schedule_day)
      assert_equal 15, @time_range.end_at.in_time_zone.hour
    end
  
    should "have duration of 120 minutes" do
      assert_equal 120 * 60, @time_range.duration
    end
  
    should "have time_start_at and time_end_at in local time" do
      assert_equal @time_range.start_at.in_time_zone.hour.hours + @time_range.start_at.in_time_zone.min.minutes, @time_range.time_start_at
      assert_equal @time_range.end_at.in_time_zone.hour.hours + @time_range.end_at.in_time_zone.min.minutes, @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      assert_equal @time_range.start_at.utc.hour.hours + @time_range.start_at.utc.min.minutes, @time_range.time_start_at_utc
      assert_equal @time_range.end_at.utc.hour.hours + @time_range.end_at.utc.min.minutes, @time_range.time_end_at_utc
    end
  
  end

  context "time range created using 24 hour notation" do
    context "morning appointment" do
      setup do
        @time_range = TimeRange.new(:day => @today, :start_at => "0300", :end_at => "0500")
      end
  
      should "start today at 3 am local time" do
        assert_equal @today, @time_range.start_at.in_time_zone.to_s(:appt_schedule_day)
        assert_equal 3, @time_range.start_at.in_time_zone.hour
      end
  
      should "end today at 5 am local time" do
        assert_equal @today, @time_range.end_at.in_time_zone.to_s(:appt_schedule_day)
        assert_equal 5, @time_range.end_at.in_time_zone.hour
      end
  
      should "have duration of 120 minutes" do
        assert_equal 120 * 60, @time_range.duration
      end

      should "have time_start_at and time_end_at in local time" do
        assert_equal @time_range.start_at.in_time_zone.hour.hours + @time_range.start_at.in_time_zone.min.minutes, @time_range.time_start_at
        assert_equal @time_range.end_at.in_time_zone.hour.hours + @time_range.end_at.in_time_zone.min.minutes, @time_range.time_end_at
      end

      should "have time_start_at_utc and time_end_at_utc in UTC time" do
        assert_equal @time_range.start_at.utc.hour.hours + @time_range.start_at.utc.min.minutes, @time_range.time_start_at_utc
        assert_equal @time_range.end_at.utc.hour.hours + @time_range.end_at.utc.min.minutes, @time_range.time_end_at_utc
      end

    end
  
    context "afternoon apointment" do
      setup do
        @time_range = TimeRange.new(:day => @today, :start_at => "1500", :end_at => "1800")
      end
    
      should "start today at 3 pm local time" do
        assert_equal @today, @time_range.start_at.in_time_zone.to_s(:appt_schedule_day)
        assert_equal 15, @time_range.start_at.in_time_zone.hour
      end
    
      should "end today at 6 pm local time" do
        assert_equal @today, @time_range.end_at.in_time_zone.to_s(:appt_schedule_day)
        assert_equal 18, @time_range.end_at.in_time_zone.hour
      end
    
      should "have duration of 180 minutes" do
        assert_equal 180 * 60, @time_range.duration
      end

      should "have time_start_at and time_end_at in local time" do
        assert_equal @time_range.start_at.in_time_zone.hour.hours + @time_range.start_at.in_time_zone.min.minutes, @time_range.time_start_at
        assert_equal @time_range.end_at.in_time_zone.hour.hours + @time_range.end_at.in_time_zone.min.minutes, @time_range.time_end_at
      end

      # Local time is Pacific time zone
      # 1500 local is 2300 in UTC
      # 1800 local is 0200 in UTC. We will add 24.hours to this.
      should "have time_start_at_utc and time_end_at_utc in UTC time" do
        assert_equal @time_range.start_at.utc.hour.hours + @time_range.start_at.utc.min.minutes, @time_range.time_start_at_utc
        assert_equal @time_range.end_at.utc.hour.hours  + @time_range.end_at.utc.min.minutes, @time_range.time_end_at_utc
      end

    end
  
    context "appointment ending at noon" do
      setup do
        @time_range = TimeRange.new(:day => @today, :start_at => "1100", :end_at => "1200")
      end
    
      should "start today at 11 am local time" do
        assert_equal @today, @time_range.start_at.in_time_zone.to_s(:appt_schedule_day)
        assert_equal 11, @time_range.start_at.in_time_zone.hour
      end
    
      should "end today at noon local time" do
        assert_equal @today, @time_range.end_at.in_time_zone.to_s(:appt_schedule_day)
        assert_equal 12, @time_range.end_at.in_time_zone.hour
      end
    
      should "have duration of 60 minutes" do
        assert_equal 60 * 60, @time_range.duration
      end

      should "have time_start_at and time_end_at in local time" do
        assert_equal @time_range.start_at.in_time_zone.hour.hours + @time_range.start_at.in_time_zone.min.minutes, @time_range.time_start_at
        assert_equal @time_range.end_at.in_time_zone.hour.hours + @time_range.end_at.in_time_zone.min.minutes, @time_range.time_end_at
      end

      should "have time_start_at_utc and time_end_at_utc in UTC time" do
        assert_equal @time_range.start_at.utc.hour.hours + @time_range.start_at.utc.min.minutes, @time_range.time_start_at_utc
        assert_equal @time_range.end_at.utc.hour.hours + @time_range.end_at.utc.min.minutes, @time_range.time_end_at_utc
      end

    end
  end

  context "time range created with default start and end times" do
    setup do
      @now        = Time.now
      @time_range = TimeRange.new(:day => @now.to_s(:appt_schedule_day))
    end
  
    should "start today at 00:00:00 hours" do
      assert_equal 0, @time_range.start_at.in_time_zone.hour
      assert_equal 0, @time_range.start_at.in_time_zone.min
      assert_equal 0, @time_range.start_at.in_time_zone.sec
      assert_equal @now.yday, @time_range.start_at.in_time_zone.yday
    end
  
    should "end tomorrow at 00:00:00" do
      assert_equal 00, @time_range.end_at.in_time_zone.hour
      assert_equal 00, @time_range.end_at.in_time_zone.min
      assert_equal 00, @time_range.end_at.in_time_zone.sec
      assert_equal @now.yday+1, @time_range.end_at.in_time_zone.yday
    end

    should "have time_start_at and time_end_at in local time" do
      # Note that we add 24 hours to the calculation of time_end_at, as the end_day is one day later than the start day
      assert_equal @time_range.start_at.in_time_zone.hour.hours + @time_range.start_at.in_time_zone.min.minutes + @time_range.start_at.in_time_zone.sec.seconds, @time_range.time_start_at
      assert_equal @time_range.end_at.in_time_zone.hour.hours + @time_range.end_at.in_time_zone.min.minutes + @time_range.end_at.in_time_zone.sec.seconds, @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      # Note that we add 24 hours to the calculation of time_end_at_utc, as the end_day is one day later than the start day
      assert_equal @time_range.start_at.utc.hour.hours + @time_range.start_at.utc.min.minutes + @time_range.start_at.utc.sec.seconds, @time_range.time_start_at_utc
      assert_equal @time_range.end_at.utc.hour.hours + @time_range.end_at.utc.min.minutes + @time_range.end_at.utc.sec.seconds, @time_range.time_end_at_utc 
    end
  
  end

  context "time range across two days created with ampm notation starting today 3pm ending tomorrow 11am" do
    setup do
      @time_range = TimeRange.new(:day => @today, :end_day => @tomorrow, :start_at => "3 pm", :end_at => "11 am")
    end
  
    should "start today at 3 pm local time" do
      assert_equal @today, @time_range.start_at.in_time_zone.to_s(:appt_schedule_day)
      assert_equal 15, @time_range.start_at.in_time_zone.hour
    end
  
    should "end tomorrow at 11am local time" do
      assert_equal @tomorrow, @time_range.end_at.in_time_zone.to_s(:appt_schedule_day)
      assert_equal 11, @time_range.end_at.in_time_zone.hour
    end
  
    should "have duration of 20 * 60 = 1200 minutes" do
      assert_equal((20.hours), @time_range.duration)
    end

    should "have time_start_at and time_end_at in local time" do
      # Note that we add 24 hours to the calculation of time_end_at, as the end_day is one day later than the start day
      assert_equal @time_range.start_at.in_time_zone.hour.hours + @time_range.start_at.in_time_zone.min.minutes, @time_range.time_start_at
      assert_equal @time_range.end_at.in_time_zone.hour.hours + @time_range.end_at.in_time_zone.min.minutes, @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      # Note that we add 24 hours to the calculation of time_end_at_utc, as the end_day is one day later than the start day
      assert_equal @time_range.start_at.utc.hour.hours + @time_range.start_at.utc.min.minutes, @time_range.time_start_at_utc
      assert_equal @time_range.end_at.utc.hour.hours + @time_range.end_at.utc.min.minutes, @time_range.time_end_at_utc
    end
  
  end

  context "time range across two days created using 24 hour notation starting today 1500 ending tomorrow 1100" do
    setup do
      @time_range = TimeRange.new(:day => @today, :end_day => @tomorrow, :start_at => "1500", :end_at => "1100")
    end

    should "start today at 3 pm local time" do
      assert_equal @today, @time_range.start_at.in_time_zone.in_time_zone.to_s(:appt_schedule_day)
      assert_equal 15, @time_range.start_at.in_time_zone.hour
    end

    should "end tomorrow at 11 am local time" do
      assert_equal @tomorrow, @time_range.end_at.in_time_zone.to_s(:appt_schedule_day)
      assert_equal 11, @time_range.end_at.in_time_zone.hour
    end

    should "have duration of 20 hours = 20 * 60 = 1200 minutes" do
      assert_equal((20.hours), @time_range.duration)
    end

    should "have time_start_at and time_end_at in local time" do
      # Note that we add 24 hours to the calculation of time_end_at, as the end_day is one day later than the start day
      assert_equal @time_range.start_at.in_time_zone.hour.hours + @time_range.start_at.in_time_zone.min.minutes, @time_range.time_start_at
      assert_equal @time_range.end_at.in_time_zone.hour.hours + @time_range.end_at.in_time_zone.min.minutes, @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      # Note that we add 24 hours to the calculation of time_end_at_utc, as the end_day is one day later than the start day
      assert_equal @time_range.start_at.utc.hour.hours + @time_range.start_at.utc.min.minutes, @time_range.time_start_at_utc
      assert_equal @time_range.end_at.utc.hour.hours + @time_range.end_at.utc.min.minutes, @time_range.time_end_at_utc
    end
  
  end

  context "time range across two days starting today 2300 ending tomorrow 0100 (testing time_start_at_utc)" do
    setup do
      @time_range = TimeRange.new(:day => @today, :end_day => @tomorrow, :start_at => "2300", :end_at => "0100")
    end

    should "have duration of 2 hours = 2 * 60 = 120 minutes" do
      assert_equal((2.hours), @time_range.duration)
    end

    should "have time_start_at and time_end_at in local time" do
      # Note that we add 24 hours to the calculation of time_end_at, as the end_day is one day later than the start day in local time
      assert_equal @time_range.start_at.in_time_zone.hour.hours + @time_range.start_at.in_time_zone.min.minutes, @time_range.time_start_at
      assert_equal @time_range.end_at.in_time_zone.hour.hours + @time_range.end_at.in_time_zone.min.minutes, @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      # Note that we add 24 hours to the calculation of time_end_at_utc. This ensures that time ranges can be compared against one another, regardless of what
      # time they actually start (before or after midnight in UTC)
      assert_equal @time_range.start_at.utc.hour.hours + @time_range.start_at.utc.min.minutes, @time_range.time_start_at_utc
      assert_equal @time_range.end_at.utc.hour.hours + @time_range.end_at.utc.min.minutes, @time_range.time_end_at_utc
    end
  
  end

  context "create a time range with the parameter anytime" do
  
    setup do
      @time_range = TimeRange.new(:when => "anytime")
    end
  
    should "have no start_at, end_at or duration" do
      assert_nil  @time_range.start_at
      assert_nil  @time_range.end_at
      assert_nil  @time_range.duration
    end
  
  end

  context "evening time range" do
    setup do
      @time_range = TimeRange.new(:day => @today, :start_at => "2000", :end_at => "2200")
    end
  
    should "have correct time_start_at and time_end_at as local time" do
      assert_equal 20 * 3600, @time_range.time_start_at
      assert_equal 22 * 3600, @time_range.time_end_at
    end
  
  end
  
  context "time range with start and duration" do
    setup do
      @time_range = TimeRange.new(:day => @today, :start_at => "0800", :duration => 2.hours)
    end
    
    should "have correct end_at and duration" do
      assert_equal 10, @time_range.end_at.in_time_zone.hour
      assert_equal 2.hours, @time_range.duration
    end
    
  end

  context "time range with Time types for start_at and end_at, not strings" do

    # Time range is tomorrow 0300 - 0500 PST
    setup do
      @time_range = TimeRange.new(:start_at => Time.zone.now.tomorrow.beginning_of_day + 3.hours, :duration => 2.hours)
    end
    
    should "have correct start and end times and duration" do
      assert_equal 3, @time_range.start_at.in_time_zone.hour
      assert_equal 5, @time_range.end_at.in_time_zone.hour
      assert_equal 2.hours, @time_range.duration
    end
    
  end
  
  context "assumption about end_day can lead to negative duration" do
    setup do
      # This will lead to a start time of 0000 tomorrow, and an end time of 0100 today without a fix in TimeRange
      @time_range = TimeRange.new(:day => @today, :start_at => "1600", :end_at => "1700")
    end
    
    should "not have a negative duration" do
      assert_true @time_range.duration >= 0
    end
  end
  
  context "test issue with DateTime types being passed in leading to zero duration" do
    setup do
      # These DateTime values are parsed into UTC
      @time_range = TimeRange.new(:start_at => DateTime.parse("12/12/2009 16:00"), :end_at => DateTime.parse("12/12/2009 18:00"))
    end
    
    should "have correct start_at, end_at, time_start_at, time_end_at and duration" do
      assert_equal ((16.hours + Time.zone.utc_offset) % 24.hours) / 1.hour, @time_range.start_at.in_time_zone.hour
      assert_equal ((18.hours + Time.zone.utc_offset) % 24.hours) / 1.hour, @time_range.end_at.in_time_zone.hour
      assert_equal 2.hours, @time_range.duration
      assert_equal 16.hours, @time_range.time_start_at_utc
      assert_equal 18.hours, @time_range.time_end_at_utc
    end
    
  end

end
