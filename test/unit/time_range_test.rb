require 'test/test_helper'

class TimeRangeTest < ActiveSupport::TestCase
  
  context "time range created with ampm notation" do
    setup do
      @tomorrow    = (Time.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
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
      assert_equal 120, @time_range.duration
    end
    
    should "have time_start_at and time_end_at in local time" do
      assert_equal (@time_range.start_at.in_time_zone.hour * 60 * 60) + (@time_range.start_at.in_time_zone.min * 60), @time_range.time_start_at
      assert_equal (@time_range.end_at.in_time_zone.hour * 60 * 60) + (@time_range.end_at.in_time_zone.min * 60), @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      assert_equal (@time_range.start_at.utc.hour * 60 * 60) + (@time_range.start_at.utc.min * 60), @time_range.time_start_at_utc 
      assert_equal (@time_range.end_at.utc.hour * 60 * 60) + (@time_range.end_at.utc.min * 60), @time_range.time_end_at_utc 
    end
    
  end
  
  context "time range created using 24 hour notation" do
    context "morning appointment" do
      setup do
        @today      = Time.now.to_s(:appt_schedule_day)
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
        assert_equal 120, @time_range.duration
      end

      should "have time_start_at and time_end_at in local time" do
        assert_equal (@time_range.start_at.in_time_zone.hour * 60 * 60) + (@time_range.start_at.in_time_zone.min * 60), @time_range.time_start_at
        assert_equal (@time_range.end_at.in_time_zone.hour * 60 * 60) + (@time_range.end_at.in_time_zone.min * 60), @time_range.time_end_at
      end

      should "have time_start_at_utc and time_end_at_utc in UTC time" do
        assert_equal (@time_range.start_at.utc.hour * 60 * 60) + (@time_range.start_at.utc.min * 60), @time_range.time_start_at_utc 
        assert_equal (@time_range.end_at.utc.hour * 60 * 60) + (@time_range.end_at.utc.min * 60), @time_range.time_end_at_utc 
      end

    end
    
    context "afternoon apointment" do
      setup do
        @today      = Time.now.to_s(:appt_schedule_day)
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
        assert_equal 180, @time_range.duration
      end

      should "have time_start_at and time_end_at in local time" do
        assert_equal (@time_range.start_at.in_time_zone.hour * 60 * 60) + (@time_range.start_at.in_time_zone.min * 60), @time_range.time_start_at
        assert_equal (@time_range.end_at.in_time_zone.hour * 60 * 60) + (@time_range.end_at.in_time_zone.min * 60), @time_range.time_end_at
      end

      should "have time_start_at_utc and time_end_at_utc in UTC time" do
        assert_equal (@time_range.start_at.utc.hour * 60 * 60) + (@time_range.start_at.utc.min * 60), @time_range.time_start_at_utc 
        assert_equal (@time_range.end_at.utc.hour * 60 * 60) + (@time_range.end_at.utc.min * 60), @time_range.time_end_at_utc 
      end

    end
    
    context "appointment ending at noon" do
      setup do
        @today      = Time.now.to_s(:appt_schedule_day)
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
        assert_equal 60, @time_range.duration
      end

      should "have time_start_at and time_end_at in local time" do
        assert_equal (@time_range.start_at.in_time_zone.hour * 60 * 60) + (@time_range.start_at.in_time_zone.min * 60), @time_range.time_start_at
        assert_equal (@time_range.end_at.in_time_zone.hour * 60 * 60) + (@time_range.end_at.in_time_zone.min * 60), @time_range.time_end_at
      end

      should "have time_start_at_utc and time_end_at_utc in UTC time" do
        assert_equal (@time_range.start_at.utc.hour * 60 * 60) + (@time_range.start_at.utc.min * 60), @time_range.time_start_at_utc 
        assert_equal (@time_range.end_at.utc.hour * 60 * 60) + (@time_range.end_at.utc.min * 60), @time_range.time_end_at_utc 
      end

    end
  end
  
  context "time range created with default start and end times" do
    setup do
      @now        = Time.now
      @time_range = TimeRange.new(:day => @now.to_s(:appt_schedule_day))
    end
    
    should "start today at 0000 hours" do
      assert_equal 0, @time_range.start_at.in_time_zone.hour
      assert_equal 0, @time_range.start_at.in_time_zone.min
      assert_equal @now.yday, @time_range.start_at.in_time_zone.yday
    end
    
    should "end tomorrow at 0000" do
      assert_equal 0, @time_range.end_at.in_time_zone.hour
      assert_equal 0, @time_range.end_at.in_time_zone.min
      assert_equal @now.yday+1, @time_range.end_at.in_time_zone.yday
    end

    should "have time_start_at and time_end_at in local time" do
      # Note that we add 24 hours to the calculation of time_end_at, as the end_day is one day later than the start day
      assert_equal (@time_range.start_at.in_time_zone.hour * 60 * 60) + (@time_range.start_at.in_time_zone.min * 60), @time_range.time_start_at
      assert_equal (@time_range.end_at.in_time_zone.hour * 60 * 60) + (@time_range.end_at.in_time_zone.min * 60) + (24 * 3600), @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      # Note that we add 24 hours to the calculation of time_end_at_utc, as the end_day is one day later than the start day
      assert_equal (@time_range.start_at.utc.hour * 60 * 60) + (@time_range.start_at.utc.min * 60), @time_range.time_start_at_utc 
      assert_equal (@time_range.end_at.utc.hour * 60 * 60) + (@time_range.end_at.utc.min * 60) + (24 * 3600), @time_range.time_end_at_utc 
    end
    
  end
  
  context "time range across two days created with ampm notation starting today 3pm ending tomorrow 11am" do
    setup do
      @today      = Time.now.to_s(:appt_schedule_day)
      @tomorrow   = (Time.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
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
      assert_equal (20*60), @time_range.duration
    end

    should "have time_start_at and time_end_at in local time" do
      # Note that we add 24 hours to the calculation of time_end_at, as the end_day is one day later than the start day
      assert_equal (@time_range.start_at.in_time_zone.hour * 60 * 60) + (@time_range.start_at.in_time_zone.min * 60), @time_range.time_start_at
      assert_equal (@time_range.end_at.in_time_zone.hour * 60 * 60) + (@time_range.end_at.in_time_zone.min * 60) + (24 * 3600), @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      # Note that we add 24 hours to the calculation of time_end_at_utc, as the end_day is one day later than the start day
      assert_equal (@time_range.start_at.utc.hour * 60 * 60) + (@time_range.start_at.utc.min * 60), @time_range.time_start_at_utc 
      assert_equal (@time_range.end_at.utc.hour * 60 * 60) + (@time_range.end_at.utc.min * 60) + (24 * 3600), @time_range.time_end_at_utc 
    end
    
  end
  
  context "time range across two days created using 24 hour notation starting today 1500 ending tomorrow 1100" do
    setup do
      @today      = Time.now.to_s(:appt_schedule_day)
      @tomorrow   = (Time.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
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
      assert_equal (20 * 60), @time_range.duration
    end

    should "have time_start_at and time_end_at in local time" do
      # Note that we add 24 hours to the calculation of time_end_at, as the end_day is one day later than the start day
        assert_equal (@time_range.start_at.in_time_zone.hour * 60 * 60) + (@time_range.start_at.in_time_zone.min * 60), @time_range.time_start_at
      assert_equal (@time_range.end_at.in_time_zone.hour * 60 * 60) + (@time_range.end_at.in_time_zone.min * 60) + (24 * 3600), @time_range.time_end_at
    end

    should "have time_start_at_utc and time_end_at_utc in UTC time" do
      # Note that we add 24 hours to the calculation of time_end_at_utc, as the end_day is one day later than the start day
      assert_equal (@time_range.start_at.utc.hour * 60 * 60) + (@time_range.start_at.utc.min * 60), @time_range.time_start_at_utc 
      assert_equal (@time_range.end_at.utc.hour * 60 * 60) + (@time_range.end_at.utc.min * 60) + (24 * 3600), @time_range.time_end_at_utc 
    end
    
  end
  
end
