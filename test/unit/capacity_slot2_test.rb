require 'test/test_helper'
require 'test/factories'

class CapacitySlot2Test < ActiveSupport::TestCase
  
  should_validate_presence_of       :start_at, :end_at, :duration
  should_validate_numericality_of   :duration
  should_validate_numericality_of   :capacity
  
  should_belong_to                  :company, :provider, :location
  
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
    assert_valid    @location

    @company        = Factory(:company, :subscription => @subscription)
    @company.locations.push(@location)
    @location.reload
    assert_valid @company
    assert_equal @company, @location.company

    @anywhere       = Location.anywhere
    @customer       = Factory(:user, :name => "Customer")
    @provider       = Factory(:user, :name => "Provider")
    @company.user_providers.push(@provider)
    @work_service   = Factory(:work_service, :name => "Work service", :price => 1.00, :duration => 60.minutes, :allow_custom_duration => true, :company => @company)
    @free_service   = @company.free_service

    assert_valid @customer
    assert_valid @provider
    assert_valid @work_service
    assert_valid @free_service

    @work_service.user_providers.push(@provider)
    assert_valid @work_service
    
    @start_tomorrow = Time.zone.now.tomorrow.beginning_of_day
    
  end

  #
  # check the change_capacity function, which reduces a capacity slot's capacity, creating new slots on either side as appropriate
  #
  context "create a single capacity slot capacity 4" do
    setup do
      # create free time from 0 to 8 tomorrow
      @slot = CapacitySlot2.create(:company => @company, :provider => @provider, :location => @location,
                                    :start_at => @start_tomorrow, :end_at => @start_tomorrow + 8.hours, :capacity => 4)
    end
      
    should_change("CapacitySlot2.count", :by => 1) { CapacitySlot2.count }
    
    should "have one capacity slot from 0 to 8 dur 8 c 4" do
      slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 8, 8.hours, 4]], slots
    end
    
    should "correctly consolidate for capacities <= 5" do
      assert_equal [[0, 8, 4]], 
        CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 1).
          map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
      assert_equal [[0, 8, 4]],
        CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 2).
          map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
      assert_equal [[0, 8, 4]],
        CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 3).
          map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
      assert_equal [[0, 8, 4]],
        CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 4).
          map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
      assert_equal [],
        CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 5).
          map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
    end
    
    context "then reduce capacity by: 3-6 c 1" do
      setup do
        CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 3.hours, @start_tomorrow + 6.hours, -1)
      end
      
      # Should have 3 total capacity slots
      should_change("CapacitySlot2.count", :by => 2) { CapacitySlot2.count }
      
      should "have capacity slots of 0-3 c 4; 3-6 c 3; 6-8 c 4" do
        # Get the capacity slots, sort by the start time and then the end time (hack...)
        slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 3, 3.hours, 4], [3, 6, 3.hours, 3], [6, 8, 2.hours, 4]], slots
      end
      
      should "correctly consolidate for capacities <= 5" do
        assert_equal [[0, 8, 3]],
          CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 1).
            map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
        assert_equal [[0, 8, 3]],
          CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 2).
            map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
        assert_equal [[0, 8, 3]],
          CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 3).
            map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
        assert_equal [[0, 3, 4], [6, 8, 4]],
          CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 4).
            map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
        assert_equal [], 
          CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 5).
            map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
      end
    
      context "then reduce capacity by: 5-7 c 2" do
        setup do
          CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 5.hours, @start_tomorrow + 7.hours, -2)
        end
      
        # Should have 5 total capacity slots
        should_change("CapacitySlot2.count", :by => 2) { CapacitySlot2.count }
              
        should "have capacity slots of 0-3 c 4; 3-5 c 3; 5-6 c 1; 6-7 c 2; 7-8 c 4" do
          # Get the capacity slots, sort by the start time, then the end time, then the capacity
          slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                    map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                    sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
          assert_equal [[0, 3, 3.hours, 4], [3, 5, 2.hours, 3], [5, 6, 1.hour, 1], [6, 7, 1.hour, 2], [7, 8, 1.hours, 4]], slots
        end
          
        should "correctly consolidate for capacities <= 5" do
          assert_equal [[0, 8, 1]], 
            CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 1).
              map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
          assert_equal [[0, 5, 3], [6, 8, 2]],
            CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 2).
              map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
          assert_equal [[0, 5, 3], [7, 8, 4]],
            CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 3).
              map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
          assert_equal [[0, 3, 4], [7, 8, 4]],
            CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 4).
              map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
          assert_equal [],
            CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 5).
              map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
        end
          
        context "then remove company" do
          setup do
            @company.destroy
          end
          
          should "have no Companies or associated models" do
            assert_equal 0, Company.count
            assert_equal 0, Appointment.count
            assert_equal 0, Subscription.count
            assert_equal 0, CompanyProvider.count
            assert_equal 0, CapacitySlot2.count
          end
          
        end
        
        context "then back out 5-7 c 2" do
          setup do
            CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 5.hours, @start_tomorrow + 7.hours, 2)
          end
          
          # Should have 3 total capacity slots
          should_change("CapacitySlot2.count", :by => -2) { CapacitySlot2.count }
          
          should "have capacity slots of 0-3 c 4; 3-6 c 3; 6-8 c 4" do
            # Get the capacity slots, sort by the start time and then the end time (hack...)
            slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                      map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                      sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
            assert_equal [[0, 3, 3.hours, 4], [3, 6, 3.hours, 3], [6, 8, 2.hours, 4]], slots
          end
          
          context "then back out 3-6 c 1" do
            
            setup do
              CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 3.hours, @start_tomorrow + 6.hours, 1)
            end
          
            # Should have 1 total capacity slots
            should_change("CapacitySlot2.count", :by => -2) { CapacitySlot2.count }
          
            should "have one capacity slot from 0 to 8 dur 8 c 4" do
              slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                        map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                        sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
              assert_equal [[0, 8, 8.hours, 4]], slots
            end
          
          end
          
        end
          
        context "then back these out forward order" do
          setup do
            CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 3.hours, @start_tomorrow + 6.hours, 1)
            CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 5.hours, @start_tomorrow + 7.hours, 2)
          end
          
          # Should have 1 total capacity slots
          should_change("CapacitySlot2.count", :by => -4) { CapacitySlot2.count }
          
          should "have one capacity slot from 0 to 8 dur 8 c 4" do
            slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                      map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                      sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
            assert_equal [[0, 8, 8.hours, 4]], slots
          end
          
        end
          
      end
    end
  end
  

  #
  # Same sequence, but this time we want to go negative
  #
  context "create a single capacity slot capacity 1" do
    setup do
      # create free time from 0 to 8 tomorrow
      @start_tomorrow = Time.zone.now.tomorrow.beginning_of_day
      @slot = CapacitySlot2.create(:company => @company, :provider => @provider, :location => @location,
                                    :start_at => @start_tomorrow, :end_at => @start_tomorrow + 8.hours, :capacity => 1)
    end
      
    should_change("CapacitySlot2.count", :by => 1) { CapacitySlot2.count }
    
    should "have one capacity slot from 0 to 8 dur 8 c 1" do
      slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
      assert_equal [[0, 8, 8.hours, 1]], slots
    end
    
    should "correctly consolidate for capacities <= 2" do
      assert_equal [[0, 8, 1]], 
        CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 1).
          map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
      assert_equal [],
        CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 2).
          map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
    end
    
    context "then reduce capacity by: 3-6 c 1" do
      setup do
        CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 3.hours, @start_tomorrow + 6.hours, -1)
      end
      
      # Should have 2 total capacity slots
      should_change("CapacitySlot2.count", :by => 1) { CapacitySlot2.count }
      
      should "have capacity slots of 0-3 c 1; 6-8 c 1" do
        # Get the capacity slots, sort by the start time and then the end time (hack...)
        slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                  map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                  sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
        assert_equal [[0, 3, 3.hours, 1], [6, 8, 2.hours, 1]], slots
      end
      
      should "correctly consolidate for capacities <= 2" do
        assert_equal [[0, 3, 1], [6, 8, 1]],
          CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 1).
            map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
        assert_equal [],
          CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 2).
            map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
      end
  
      should "raise exception if we reduce capacity by 5-7 c 2" do
        assert_raise AppointmentInvalid, "No capacity available" do
          CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 5.hours, @start_tomorrow + 7.hours, -2)
        end
      end
      
  
      context "then reduce capacity by: 5-7 c 2" do
        setup do
          CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 5.hours, @start_tomorrow + 7.hours, -2, :force => true)
        end
      
        # Should have 5 total capacity slots
        should_change("CapacitySlot2.count", :by => 2) { CapacitySlot2.count }
              
        should "have capacity slots of 0-3 c 1; 5-6 c -2; 6-7 c -1; 7-8 c 1" do
          # Get the capacity slots, sort by the start time, then the end time, then the capacity
          slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                    map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                    sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
          assert_equal [[0, 3, 3.hours, 1], [5, 6, 1.hour, -2], [6, 7, 1.hour, -1], [7, 8, 1.hours, 1]], slots
        end
        
        should "correctly consolidate for capacities <= 2" do
          assert_equal [[0, 3, 1], [7, 8, 1]],
            CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 1).
              map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
          assert_equal [],
            CapacitySlot2.consolidate_slots_for_capacity((@company.capacity_slot2s.provider(@provider).general_location(@location)), 2).
              map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.capacity] }.sort
        end
  
        context "then back out 5-7 c 2" do
          setup do
            CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 5.hours, @start_tomorrow + 7.hours, 2)
          end
          
          # Should have 3 total capacity slots
          should_change("CapacitySlot2.count", :by => -2) { CapacitySlot2.count }
  
          should "have capacity slots of 0-3 c 1; 6-8 c 1" do
            # Get the capacity slots, sort by the start time and then the end time (hack...)
            slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                      map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                      sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
            assert_equal [[0, 3, 3.hours, 1], [6, 8, 2.hours, 1]], slots
          end
          
          context "then back out 3-6 c 1" do
            
            setup do
              CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 3.hours, @start_tomorrow + 6.hours, 1)
            end
          
            # Should have 1 total capacity slots
            should_change("CapacitySlot2.count", :by => -1) { CapacitySlot2.count }
          
            should "have one capacity slot from 0 to 8 dur 8 c 1" do
              slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                        map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                        sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
              assert_equal [[0, 8, 8.hours, 1]], slots
            end
          
          end
  
        end
  
        context "then back these out forward order" do
          setup do
            CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 3.hours, @start_tomorrow + 6.hours, 1)
            CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 5.hours, @start_tomorrow + 7.hours, 2)
          end
          
          # Should have 1 total capacity slots
          should_change("CapacitySlot2.count", :by => -3) { CapacitySlot2.count }
          
          should "have one capacity slot from 0 to 8 dur 8 c 1" do
            slots = @company.capacity_slot2s.provider(@provider).general_location(@location).
                      map{|s| [s.start_at.in_time_zone.hour, s.end_at.in_time_zone.hour, s.duration, s.capacity]}.
                      sort{|s, t| ((s[0] * 10000) + (s[1] * 100) + s[3]) <=> ((t[0] * 10000) + (t[1] * 100) + t[3])}
            assert_equal [[0, 8, 8.hours, 1]], slots
          end
  
        end
  
      end
    end
  end
  
  context "with no capacity" do
    should "raise exception if we reduce capacity by 5-7 c 2" do
      assert_raise AppointmentInvalid, "No capacity available" do
        CapacitySlot2.change_capacity(@company, @location, @provider, @start_tomorrow + 5.hours, @start_tomorrow + 7.hours, -2)
      end
    end
  end

end
