require 'test/test_helper'
require 'test/factories'

class CapacitySlotTest < ActiveSupport::TestCase
  
  should_belong_to                  :free_appointment
  
  should_validate_presence_of       :start_at, :end_at, :duration  
  
  def setup
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
    assert_valid    @company
    assert_equal @company, @location.company

    @anywhere       = Location.anywhere
    @customer       = Factory(:user, :name => "Customer", :companies => [@company])
    @provider       = Factory(:user, :name => "Provider", :companies => [@company])
    @work_service   = Factory(:work_service, :name => "Work service", :companies => [@company], :price => 1.00, :duration => 60, :allow_custom_duration => true)
    @free_service   = @company.free_service

    assert_valid @customer
    assert_valid @provider
    assert_valid @work_service
    assert_valid @free_service

    @work_service.providers.push(@provider)
    assert_valid @work_service
  end

  #
  # schedule some free time and appointments at the start of the day
  #
  # context "create free time from 0000 to 0800 tomorrow" do
  #   setup do
  #     # create free time from 0000 to 0800 tomorrow
  #     @tomorrow       = Time.now.tomorrow.to_s(:appt_schedule_day) # e.g. 20081201
  #     @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0000", :end_at => "0800"})
  #     @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service, :time_range => @time_range)
  #   end
  #   
  #   should_change "Appointment.count", :by => 1
  #   
  #   should_change "CapacitySlot.count", :by => 1
  #   
  #   should "have one capacity slot from 0000 to 0800 duration 8 hours" do
  #     assert_equal 8 * 60, CapacitySlot.first.duration
  #   end
  #   
  #   context "THEN find free time from 0300 to 0600" do
  #     
  #     setup do
  #       @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0300", :end_at => "0600"})
  #       @date_range     = DateRange.parse_when("tomorrow")
  #       @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service, @time_range.duration, @date_range, {:time_range => @time_range})
  #     end
  #     
  #     should "have one capacity slot of duration 8 hours" do
  #       assert_equal 1, @capacity_slots.size
  #       assert_equal 8 * 60, @capacity_slots.first.duration
  #     end
  #     
  #     context "THEN schedule work appointment from 0300 to 0600" do
  #       setup do
  #         @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
  #         @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
  #         assert_valid @work_appt
  #         @free_appt.reload # Reload the capacity slots list
  #       end
  # 
  #       # After scheduling the appointment, we have available capacity from 0000 - 0300 and 0600 - 0800
  #       should "have 2 capacity slots" do
  #         assert_equal 2, @free_appt.capacity_slots.size
  #         
  #       end
  #       
  #       should "have capacity slots with durations 3 hours and 2 hours" do
  #         assert_equal [2*60, 3*60], @free_appt.capacity_slots.map(&:duration).sort
  #       end
  #       
  #       context "THEN find free time from 0100 to 0200" do
  #         
  #         setup do
  #           @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0100", :end_at => "0200"})
  #           @date_range     = DateRange.parse_when("tomorrow")
  #           @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
  #                                                                           @time_range.duration, @date_range, {:time_range => @time_range})
  #         end
  # 
  #         # This should give the capacity slot from 0000 - 0300
  #         should "have one capacity slot" do
  #           assert_equal 1, @capacity_slots.size
  #         end
  #         
  #         context "THEN schedule a work appointment from 0100 to 0200" do
  #           setup do
  #             @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
  #             @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
  #             assert_valid @work_appt
  #             @free_appt.reload # Reload the capacity slots list
  #           end
  #   
  #           # I should now have capacity from 0000- 0100, 0200 - 0300 and 0600 - 0800
  #           should "have 3 capacity slots" do
  #             assert_equal 3, @free_appt.capacity_slots.size
  #           end
  #           
  #           should "have capacity slots with durations 1 hour, 1 hour and 2 hours" do
  #             assert_equal [1*60, 1*60, 2*60], @free_appt.capacity_slots.map(&:duration).sort
  #           end
  # 
  #           context "THEN find free time from 0500 to 0700" do
  #             setup do
  #               @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0500", :end_at => "0700"})
  #               @date_range     = DateRange.parse_when("tomorrow")
  #               @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
  #                                                                               @time_range.duration, @date_range, {:time_range => @time_range})
  #             end
  # 
  #             # This should give no slots
  #             should "have no capacity slots" do
  #               assert_equal 0, @capacity_slots.size
  #             end
  # 
  #           end
  #           
  #           context "THEN find free time from 0600 to 0800" do
  #             setup do
  #               @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0600", :end_at => "0800"})
  #               @date_range     = DateRange.parse_when("tomorrow")
  #               @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
  #                                                                               @time_range.duration, @date_range, {:time_range => @time_range})
  #             end
  # 
  #             # This should give one slot, from 0600- 0800
  #             should "have no capacity slots" do
  #               assert_equal 1, @capacity_slots.size
  #               assert_equal (2 * 60), @capacity_slots.first.duration
  #             end
  # 
  #             context "THEN schedule a work appointment from 0600 to 0800" do
  #               setup do
  #                 @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
  #                 @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
  #                 assert_valid @work_appt
  #                 @free_appt.reload # Reload the capacity slots list
  #               end
  # 
  #               # Should now have capacity from 0000 - 0100, 0200 - 0300
  #               should "have 2 capacity slots" do
  #                 assert_equal 2, @free_appt.capacity_slots.size
  #               end
  #               
  #             end
  #             
  #           end
  #           
  #         end
  #         
  #       end
  #     
  #     end
  #   
  #   end
  #   
  # end
  
  #
  # schedule exactly the same free and work appointments, but across two days
  # This is to try to identify time zone issues
  #
  context "create free time from 2100 tomorrow to 0500 the following day" do
    setup do
      # create free time from 2100 tomorrow to 0500 the day after
      @tomorrow       = Time.now.tomorrow.to_s(:appt_schedule_day) # e.g. 20081201
      @day_after      = (Time.now + 2.days).to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @tomorrow, :end_day => @day_after, :start_at => "2100", :end_at => "0500"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service, :time_range => @time_range)
    end
    
    should_change "Appointment.count", :by => 1
    
    should_change "CapacitySlot.count", :by => 1
    
    should "have one capacity slot from 2100 to 0500 duration 8 hours" do
      assert_equal 8 * 60, CapacitySlot.first.duration
    end
    
    context "THEN find free time from 0000 to 0300" do
      
      setup do
        @time_range     = TimeRange.new({:day => @day_after, :end_day => @day_after, :start_at => "0000", :end_at => "0300"})
        @date_range     = DateRange.parse_when("tomorrow")
        @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service, @time_range.duration, @date_range, {:time_range => @time_range})
      end
      
      should "have one capacity slot of duration 8 hours" do
        assert_equal 1, @capacity_slots.size
        assert_equal 8 * 60, @capacity_slots.first.duration
      end
      
      context "THEN schedule work appointment from 0000 to 0300" do
        setup do
          @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
          @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
          assert_valid @work_appt
          @free_appt.reload # Reload the capacity slots list
        end

        # After scheduling the appointment, we have available capacity from 2100 - 0000 and 0300 - 0500
        should "have 2 capacity slots" do
          assert_equal 2, @free_appt.capacity_slots.size
          
        end
        
        should "have capacity slots with durations 3 hours and 2 hours" do
          assert_equal [2*60, 3*60], @free_appt.capacity_slots.map(&:duration).sort
        end
        
        context "THEN find free time from 2200 to 2300" do
          
          setup do
            @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "2200", :end_at => "2300"})
            @date_range     = DateRange.parse_when("tomorrow")
            @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
                                                                            @time_range.duration, @date_range, {:time_range => @time_range})
          end

          # This should give the capacity slot from 2100 - 0000
          should "have one capacity slot" do
            assert_equal 1, @capacity_slots.size
          end
          
          context "THEN schedule a work appointment from 2200 to 2300" do
            setup do
              @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
              @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
              assert_valid @work_appt
              @free_appt.reload # Reload the capacity slots list
            end
    
            # I should now have capacity from 2100- 2200, 2300 - 0000 and 0300 - 0500
            should "have 3 capacity slots" do
              assert_equal 3, @free_appt.capacity_slots.size
            end
            
            should "have capacity slots with durations 1 hour, 1 hour and 2 hours" do
              assert_equal [1*60, 1*60, 2*60], @free_appt.capacity_slots.map(&:duration).sort
            end

            context "THEN find free time from 0500 to 0700" do
              setup do
                @time_range     = TimeRange.new({:day => @day_after, :end_day => @day_after, :start_at => "0500", :end_at => "0700"})
                @date_range     = DateRange.parse_when("tomorrow")
                @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
                                                                                @time_range.duration, @date_range, {:time_range => @time_range})
              end

              # This should give no slots
              should "have no capacity slots" do
                assert_equal 0, @capacity_slots.size
              end

            end
            
            context "THEN find free time from 0300 to 0500 with date range tomorrow" do
              setup do
                @time_range     = TimeRange.new({:day => @day_after, :end_day => @day_after, :start_at => "0300", :end_at => "0500"})
                @date_range     = DateRange.parse_when("tomorrow")
                @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
                                                                                @time_range.duration, @date_range, {:time_range => @time_range})
              end

              # This should give no slots as the available time is not tomorrow, but the day after
              should "have no capacity slots" do
                assert_equal 0, @capacity_slots.size
              end
            end
            
            context "THEN find free time from 0300 to 0500 with date range this week" do
              setup do
                @time_range     = TimeRange.new({:day => @day_after, :end_day => @day_after, :start_at => "0300", :end_at => "0500"})
                @date_range     = DateRange.parse_when("this week")
                @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
                                                                                @time_range.duration, @date_range, {:time_range => @time_range})
              end

              # This should give one slot, from 0300 - 0500
              should "have one capacity slot of 2 hours" do
                assert_equal 1, @capacity_slots.size
                assert_equal (2 * 60), @capacity_slots.first.duration
              end

              context "THEN schedule a work appointment from 0300 to 0500" do
                setup do
                  @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
                  @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
                  assert_valid @work_appt
                  @free_appt.reload # Reload the capacity slots list
                end

                # Should now have capacity from 2100 - 2200, 2300 - 0000
                should "have 2 capacity slots" do
                  assert_equal 2, @free_appt.capacity_slots.size
                end
                
              end
              
            end
            
          end
          
        end
      
      end
    
    end
    
  end

  #
  # The following test is the same as the first sequence, but with different capacities
  #
  
  # context "create free time from 0000 to 0800 with capacity 4 tomorrow" do
  #   setup do
  #     # create free time from 0000 to 0800 tomorrow
  #     @tomorrow       = Time.now.tomorrow.to_s(:appt_schedule_day) # e.g. 20081201
  #     @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0000", :end_at => "0800"})
  #     @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service, :time_range => @time_range, :capacity => 4)
  #   end
  #   
  #   # should_change "Appointment.count", :by => 1
  #   # 
  #   # should_change "CapacitySlot.count", :by => 1
  #   
  #   context "THEN find free time from 0300 to 0600" do
  #     
  #     setup do
  #       @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0300", :end_at => "0600"})
  #       @date_range     = DateRange.parse_when("tomorrow")
  #       @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service, @time_range.duration, @date_range, {:time_range => @time_range})
  #     end
  #     
  #     should "have one capacity slot" do
  #       assert_equal 1, @capacity_slots.size
  #     end
  #     
  #     context "THEN schedule work appointment from 0300 to 0600" do
  #       setup do
  #         @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
  #         @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
  #         assert_valid @work_appt
  #         @free_appt.reload # Reload the capacity slots list
  #       end
  # 
  #       should "have 3 capacity slots" do
  #         assert_equal 3, @free_appt.capacity_slots.size
  #       end
  #       
  #       should "have capacity slots with specific duration" do
  #         assert_equal [2*60, 3*60, 8*60], @free_appt.capacity_slots.map(&:duration).sort
  #       end
  #       
  #       context "THEN find free time from 0100 to 0200 capacity 3" do
  #         
  #         setup do
  #           @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0100", :end_at => "0200"})
  #           @date_range     = DateRange.parse_when("tomorrow")
  #           @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
  #                                                                           @time_range.duration, @date_range, {:time_range => @time_range}, {:capacity => 3})
  #         end
  #         
  #         should "have two capacity slots" do
  #           assert_equal 2, @capacity_slots.size
  #         end
  #         
  #         context "THEN schedule a work appointment from 0100 to 0200" do
  #           setup do
  #             @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at, :capacity => 3}
  #             @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
  #             assert_valid @work_appt
  #             @free_appt.reload # Reload the capacity slots list
  #           end
  #   
  #           # TODO - this should be 4 slots
  #           should "have 5 capacity slots" do
  #             assert_equal 5, @free_appt.capacity_slots.size
  #           end
  #           
  #           context "THEN find free time from 0500 to 0700 capacity 2" do
  #             setup do
  #               @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0500", :end_at => "0700"})
  #               @date_range     = DateRange.parse_when("tomorrow")
  #               @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
  #                                                                               @time_range.duration, @date_range, {:time_range => @time_range}, {:capacity => 2})
  #             end_at
  # 
  #             should "have two capacity slots" do
  #               assert_equal 2, @capacity_slots.size
  #             end
  # 
  #             context "THEN schedule a work appointment from 0100 to 0200" do
  #               setup do
  #                 @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
  #                 @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
  #                 assert_valid @work_appt
  #                 @free_appt.reload # Reload the capacity slots list
  #               end
  # 
  #               should "have 5 capacity slots" do
  #                 assert_equal 5, @free_appt.capacity_slots.size
  #               end
  #             
  #           end
  #           
  #         end
  #         
  #       end
  #     
  #     end
  #   
  #   end
  #   
  # end
  
  #
  # schedule exactly the same free and work appointments, but at the end of the day
  # This is to try to identify time zone issues
  #
  # context "create free time from 1500 to 2300 with capacity 4 tomorrow" do
  #   setup do
  #     # create free time from 0000 to 0800 tomorrow
  #     @tomorrow       = Time.now.tomorrow.to_s(:appt_schedule_day) # e.g. 20081201
  #     @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "1500", :end_at => "2300"})
  #     @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service, :time_range => @time_range, :capacity => 4)
  #   end
  # 
  #   # should_change "Appointment.count", :by => 1
  #   # 
  #   # should_change "CapacitySlot.count", :by => 1
  # 
  #   context "THEN find free time from 1800 to 2100" do
  # 
  #     setup do
  #       @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "1800", :end_at => "2100"})
  #       @date_range     = DateRange.parse_when("tomorrow")
  #       @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service, @time_range.duration, @date_range, {:time_range => @time_range})
  #     end
  # 
  #     should "have one capacity slot" do
  #       assert_equal 1, @capacity_slots.size
  #     end
  # 
  #     context "THEN schedule work appointment from 1800 to 2100" do
  #       setup do
  #         @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
  #         @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
  #         assert_valid @work_appt
  #         @free_appt.reload # Reload the capacity slots list
  #       end
  # 
  #       should "have 3 capacity slots" do
  #         assert_equal 3, @free_appt.capacity_slots.size
  #       end
  # 
  #       should "have capacity slots with specific duration" do
  #         assert_equal [2*60, 3*60, 8*60], @free_appt.capacity_slots.map(&:duration).sort
  #       end
  # 
  #       context "THEN find free time from 1600 to 1700" do
  # 
  #         setup do
  #           @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "1600", :end_at => "1700"})
  #           @date_range     = DateRange.parse_when("tomorrow")
  #           @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service,
  #                                                                           @time_range.duration, @date_range, {:time_range => @time_range})
  #         end
  # 
  #         should "have two capacity slots" do
  #           assert_equal 2, @capacity_slots.size
  #         end
  # 
  #         context "THEN schedule a work appointment from 1600 to 1700" do
  #           setup do
  #             @options    = {:start_at => @time_range.start_at, :end_at => @time_range.end_at}
  #             @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @time_range.duration, @customer, @options)
  #             assert_valid @work_appt
  #             @free_appt.reload # Reload the capacity slots list
  #           end
  # 
  #           should "have 5 capacity slots" do
  #             assert_equal 5, @free_appt.capacity_slots.size
  #           end
  # 
  #         end
  # 
  #       end
  # 
  #     end
  # 
  #   end
  # 
  # end
  # 
  
  # 
  # context "find free time at the start of the free appointment" do
  # 
  #   setup do
  #     @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "1000", :end_at => "1100"})
  #     @date_range     = DateRange.parse_when("tomorrow")
  #     @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service, @time_range.duration, @date_range)        
  #   end
  # 
  #   context "and schedule work appointment" do
  #     setup do
  #       @options    = {:start_at => @time_range.start_at}
  #       @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @work_service.duration, @customer, @options)
  #       assert_valid @work_appt
  #       @free_appt.reload # Reload the capacity slots list
  #     end
  # 
  #     should "have 2 capacity slots" do
  #       assert_equal 2, @free_appt.capacity_slots.size
  #     end
  #   end
  # 
  # end
  # 
  # context "find free time at the end of the free appointment" do
  # 
  #   setup do
  #     @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "1100", :end_at => "1200"})
  #     @date_range     = DateRange.parse_when("tomorrow")
  #     @capacity_slots = AppointmentScheduler.find_free_capacity_slots(@company, @anywhere, @provider, @work_service, @time_range.duration, @date_range)        
  #   end
  # 
  #   context "and schedule work appointment" do
  #     setup do
  #       @options    = {:start_at => @time_range.start_at}
  #       @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @work_service.duration, @customer, @options)
  #       assert_valid @work_appt
  #       @free_appt.reload # Reload the capacity slots list
  #     end
  # 
  #     should "have 2 capacity slots" do
  #       assert_equal 2, @free_appt.capacity_slots.size
  #     end
  #   end
  # 
  # end
    
end