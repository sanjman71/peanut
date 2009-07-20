require 'test/test_helper'
require 'test/factories'

class BenchmarkRecurrenceTest < ActiveSupport::TestCase
      
  def setup
    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @anywhere       = Location.anywhere
    @customer       = Factory(:user, :name => "Customer", :companies => [@company])
    @provider       = Factory(:user, :name => "Provider", :companies => [@company])
    @work_service   = Factory(:work_service, :name => "Work service", :companies => [@company], :price => 1.00)
    @free_service   = @company.free_service
  end

  context "Benchmark run" do
    setup do
      @now            = Time.now
      @start_at       = (@now - 6.months).beginning_of_day
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 4.weeks
      @recur_days     = "#{ical_days([(@start_at + 2.days)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
      @recurrence     = Appointment.create(:company => @company, :start_at => @start_at, :end_at => @end_at, :mark_as => "free",
                                          :recur_rule => @recur_rule, :name => "Benchmarking", 
                                          :description => "Benchmarking", :public => true)
      assert_valid @recurrence
      @appointments   = @recurrence.expand_recurrence(@now, @now + 4.weeks, 3)
    end
  
    should_change "Appointment.recurring.count", :by => 1
  
  end

end
