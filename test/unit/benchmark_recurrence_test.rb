require 'test/test_helper'
require 'test/factories'

class BenchmarkRecurrenceTest < ActiveSupport::TestCase
    
  DAYS_OF_WEEK = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU']
  
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
      @start_at_utc   = Time.now.utc.beginning_of_day
      @end_at_utc     = @start_at_utc + 2.hours
      @end_recurrence = @start_at_utc + 4.weeks
      @recur_days     = "#{DAYS_OF_WEEK[(Time.now + 2.days).wday]}"
      @rrule          = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
      @recurrence     = Recurrence.create(:company => @company, :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => "free",
                                          :rrule => @rrule, :name => "Benchmarking", 
                                          :description => "Benchmarking", :public => true)
    end
  
    should_change "Appointment.count", :by => 4
  
  end

end
