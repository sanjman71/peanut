require 'test/test_helper'

class CapacitySlotProviderTest < ActiveSupport::TestCase
    
  def setup
    # Make sure we know what time zone we're in
    Time.zone = "Pacific Time (US & Canada)"

    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @us             = Factory(:us)
    @il             = Factory(:il, :country => @us)
    @chicago        = Factory(:chicago, :state => @il)
    @z60610         = Factory(:zip, :name => "60610", :state => @il)
    @location       = Factory(:location, :street_address => "123 main st.", :country => @us, :state => @il, :city => @chicago, :zip => @zip)
    @location2      = Factory(:location, :street_address => "456 side st.", :country => @us, :state => @il, :city => @chicago, :zip => @zip)
    assert_valid    @location
    assert_valid    @location2

    @company        = Factory(:company, :subscription => @subscription)
    @company.locations.push(@location)
    @company.locations.push(@location2)
    @location.reload
    assert_valid @company
    assert_equal @company, @location.company
    assert_equal @company, @location2.company

    @anywhere       = Location.anywhere
    @customer       = Factory(:user, :name => "Customer")
    @provider1      = Factory(:user, :name => "Provider 1")
    @company.user_providers.push(@provider1)
    @provider2      = Factory(:user, :name => "Provider 2")
    @company.user_providers.push(@provider2)
    @work_service   = Factory(:work_service, :name => "Work service", :price => 1.00, :duration => 60.minutes, :allow_custom_duration => true, :company => @company)
    @free_service   = @company.free_service

    assert_valid @customer
    assert_valid @provider1
    assert_valid @provider2
    assert_valid @work_service
    assert_valid @free_service

    @work_service.user_providers.push(@provider1)
    @work_service.user_providers.push(@provider2)
    assert_valid @work_service

    @start_tomorrow = Time.zone.now.tomorrow.beginning_of_day
  end

  context "create one capacity slot for two different providers" do
    setup do
      @tomorrow   = Time.zone.now.tomorrow.to_s(:appt_schedule_day) # e.g. 20081201

      # create free time from 0 to 8 tomorrow for a provider
      @time_range = TimeRange.new({:day => @tomorrow, :start_at => "0000", :end_at => "0800"})
      @free_appt1 = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider1, :time_range => @time_range, :capacity => 4)

      # create free time from 8 to 12 tomorrow for provider 2
      @time_range = TimeRange.new({:day => @tomorrow, :start_at => "0800", :end_at => "1200"})
      @free_appt2 = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider2, :time_range => @time_range, :capacity => 4)
    end

    should_change("Appointment.count", :by => 2) { Appointment.count }
    should_change("CapacitySlot.count", :by => 2) { CapacitySlot.count }
    
    should "have 2 capacity slot from 0 to 8 dur 8 c 4, and 8 to 12 dur 4 c 4" do
      assert_equal [[0, 8, 8.hours, 4], [8, 12, 4.hours, 4]], @company.capacity_slots.map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity] }
    end

    should "not consolidate slots from different providers" do
      assert_equal [[0, 8, 4], [8, 12, 4]],
        (CapacitySlot.consolidate_slots_for_capacity(@company.capacity_slots, 1)).map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort

    end
  end

end