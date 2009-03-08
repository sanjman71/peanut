require 'test/test_helper'

class TimeRangeTest < ActiveSupport::TestCase
  
  context "time range created with ampm notation" do
    setup do
      @tomorrow    = (Time.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
      @time_range  = TimeRange.new(:day => @tomorrow, :start_at => "1 pm", :end_at => "3 pm")
    end
    
    should "start tomorrow at 1 pm local time" do
      assert_equal @tomorrow, @time_range.start_at.to_s(:appt_schedule_day)
      assert_equal 13, @time_range.start_at.hour
    end
    
    should "end tomorrow at 3 pm local time" do
      assert_equal @tomorrow, @time_range.start_at.to_s(:appt_schedule_day)
      assert_equal 15, @time_range.end_at.hour
    end
    
    should "have duration of 120 minutes" do
      assert_equal 120, @time_range.duration
    end
  end
  
  context "time range created using 24 hour notation" do
    context "morning appointment" do
      setup do
        @today      = Time.now.to_s(:appt_schedule_day)
        @time_range = TimeRange.new(:day => @today, :start_at => "0300", :end_at => "0500")
      end
    
      should "start today at 3 am local time" do
        assert_equal @today, @time_range.start_at.to_s(:appt_schedule_day)
        assert_equal 3, @time_range.start_at.hour
      end
    
      should "end today at 5 am local time" do
        assert_equal @today, @time_range.end_at.to_s(:appt_schedule_day)
        assert_equal 5, @time_range.end_at.hour
      end
    
      should "have duration of 120 minutes" do
        assert_equal 120, @time_range.duration
      end
    end
    
    context "afternoon apointment" do
      setup do
        @today      = Time.now.to_s(:appt_schedule_day)
        @time_range = TimeRange.new(:day => @today, :start_at => "1500", :end_at => "1800")
      end
      
      should "start today at 3 pm local time" do
        assert_equal @today, @time_range.start_at.to_s(:appt_schedule_day)
        assert_equal 15, @time_range.start_at.hour
      end
      
      should "end today at 6 pm local time" do
        assert_equal @today, @time_range.end_at.to_s(:appt_schedule_day)
        assert_equal 18, @time_range.end_at.hour
      end
      
      should "have duration of 180 minutes" do
        assert_equal 180, @time_range.duration
      end
    end
    
    context "appointment ending at noon" do
      setup do
        @today      = Time.now.to_s(:appt_schedule_day)
        @time_range = TimeRange.new(:day => @today, :start_at => "1100", :end_at => "1200")
      end
      
      should "start today at 11 am local time" do
        assert_equal @today, @time_range.start_at.to_s(:appt_schedule_day)
        assert_equal 11, @time_range.start_at.hour
      end
      
      should "end today at noon local time" do
        assert_equal @today, @time_range.end_at.to_s(:appt_schedule_day)
        assert_equal 12, @time_range.end_at.hour
      end
      
      should "have duration of 60 minutes" do
        assert_equal 60, @time_range.duration
      end
    end
  end
  
  context "time range created with default start and end times" do
    setup do
      @now        = Time.now
      @time_range = TimeRange.new(:day => @now.to_s(:appt_schedule_day))
    end
    
    should "start today at 0000 hours" do
      assert_equal 0, @time_range.start_at.hour
      assert_equal 0, @time_range.start_at.min
      assert_equal @now.yday, @time_range.start_at.yday
    end
    
    should "end tomorrow at 0000" do
      assert_equal 0, @time_range.end_at.hour
      assert_equal 0, @time_range.end_at.min
      assert_equal @now.yday+1, @time_range.end_at.yday
    end
  end
  
end