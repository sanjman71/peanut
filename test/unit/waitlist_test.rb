require 'test/test_helper'

class WaitlistTest < ActiveSupport::TestCase
  should_belong_to              :company
  should_belong_to              :service
  should_belong_to              :provider
  should_belong_to              :customer
  should_belong_to              :location

  should_validate_presence_of   :company_id
  should_validate_presence_of   :service_id
  should_validate_presence_of   :customer_id

  should_have_many              :waitlist_time_ranges

  def setup
    @company        = Factory(:company, :name => "My Company")
    @provider       = Factory(:user, :name => "Provider")
    @company.user_providers.push(@provider)
    @company.reload
    @work_service   = Factory.build(:work_service, :name => "Work service", :price => 1.00)
    @work_service.user_providers.push(@provider)
    @company.services.push(@work_service)
    @customer       = Factory(:user, :name => "Customer")
    @free_service   = @company.free_service
  end

  context "create" do
    context "with no time range attributes" do
      setup do
        @waitlist = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }

      should "add 'company customer' role on company to customer" do
        assert_equal ['company customer'], @customer.reload.roles_on(@company).collect(&:name).sort
      end
    end

    context "with time range attributes" do
      setup do
        # wait_attrs  = [{:start_date => "10/01/2009", :end_date => "10/02/2009", :start_time => "0900", :end_time => "1100"}]
        wait_attrs  = [{:start_date => "10/01/2009", :end_date => "10/02/2009", :start_time_hours => "0900", :end_time => "1100"}]
        # Note: Rails doesn't support this yet
        # @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer,
        #                                         :waitlist_time_ranges_attributes => wait_attrs)
        @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
        @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }
      should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }

      should "expand waitlist to 2 days" do
        assert_equal 2, @waitlist.expand_days.size
      end

      should "expand waitlist to 1 day with start day constraint" do
        assert_equal 1, @waitlist.expand_days(:start_day => DateTime.parse("20091002")).size
      end

      should "expand waitlist to 1 day with end day constraint" do
        assert_equal 1, @waitlist.expand_days(:end_day => DateTime.parse("20091001")).size
      end

      should "expand waitlist to 0 days with start and end day constraints" do
        assert_equal 0, @waitlist.expand_days(:start_day => DateTime.parse("20091003"), :end_day => DateTime.parse("20091005")).size
      end

      should "add 'company customer' role on company to customer" do
        assert_equal ['company customer'], @customer.reload.roles_on(@company).collect(&:name).sort
      end
    end
  end
  
  context "waitlist time range" do
    context "using regular attributes" do
      setup do
        @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
        @time_range = @waitlist.waitlist_time_ranges.create(:start_date => "10/01/2009", :end_date => "10/02/2009",
                                                            :start_time => "0930", :end_time => "1100")
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }
      should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }

      should "not change start time" do
        assert_equal 930, @time_range.start_time
      end

      should "not change end time" do
        assert_equal 1100, @time_range.end_time
      end
    end

    context "using virtual attributes" do
      setup do
        @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
        @time_range = @waitlist.waitlist_time_ranges.create(:start_date => "10/01/2009", :end_date => "10/02/2009",
                                                            :start_time_hours => "093000", :end_time_hours => "110000")
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }
      should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }

      should "change start time to utc seconds" do
        @time_utc = Time.zone.parse(Time.zone.now.to_s(:appt_schedule_day) + "0900").utc
        assert_equal (@time_utc.hour * 3600 + 30 * 60), @time_range.start_time
      end

      should "change end time to utc seconds" do
        @time_utc = Time.zone.parse(Time.zone.now.to_s(:appt_schedule_day) + "1100").utc
        assert_equal (@time_utc.hour * 3600), @time_range.end_time
      end
    end

    context "start and end time conversions" do
      setup do
        @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
        @time_range = @waitlist.waitlist_time_ranges.create(:start_date => "10/01/2009", :end_date => "10/02/2009",
                                                            :start_time_hours => "093000", :end_time_hours => "110000")
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }
      should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }
      
      should "have start_time_hours_ampm == '09:30 AM'" do
        assert_equal "09:30 AM", @time_range.start_time_hours_ampm
      end

      should "have end_time_hours_ampm == '11:00 AM'" do
        assert_equal "11:00 AM", @time_range.end_time_hours_ampm
      end
    end

    context "manage create/destroy cycle" do
      setup do
        @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
        @time_range = @waitlist.waitlist_time_ranges.create(:start_date => "10/01/2009", :end_date => "10/02/2009",
                                                            :start_time_hours => "093000", :end_time_hours => "110000")
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }
      should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }

      context "then delete waitlist" do
        setup do
          @waitlist.destroy
        end

        should_change("waitlist count", :by => -1) { Waitlist.count }
        should_change("waitlist time range count", :by => -1) { WaitlistTimeRange.count }

        should "delete waitlist time range" do
          assert_nil WaitlistTimeRange.find_by_id(@time_range.id)
        end
      end
    end
  end

  context "past" do
    setup do
      # create waitlist with past time range
      past        = (Time.zone.now - 1.day).to_s(:appt_schedule_day)
      wait_attrs  = [{:start_date => past, :end_date => past, :start_time_hours => "090000", :end_time_hours => "110000"}]
      @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
      @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
    end

    should_change("waitlist count", :by => 1) { Waitlist.count }
    should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }

    should "have waitlist in the past" do
      assert_equal [@waitlist], Waitlist.past
    end
    
    should "have time range in the past" do
      assert_equal @waitlist.waitlist_time_ranges, WaitlistTimeRange.past
    end
  end
  
  context "future" do
    setup do
      # create waitlist with future time range
      future      = (Time.zone.now + 1.day).to_s(:appt_schedule_day)
      wait_attrs  = [{:start_date => future, :end_date => future, :start_time_hours => "090000", :end_time => "110000"}]
      @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
      @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
    end
    
    should_change("waitlist count", :by => 1) { Waitlist.count }
    should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }
    
    should "not have waitlist in the past" do
      assert_equal [], Waitlist.past
    end

    should "not have time range in the past" do
      assert_equal [], WaitlistTimeRange.past
    end
  end

  context "overlapping free and wait" do
    setup do
      # create future free appoinment
      @tomorrow       = (Time.zone.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
      @tomorrow_plus1 = (Time.zone.now + 2.days).to_s(:appt_schedule_day)
      @yesterday      = (Time.zone.now - 1.day).to_s(:appt_schedule_day)
      @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0800", :end_at => "1200"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service, :time_range => @time_range)
    end

    context "where wait date range does not overlap with free time" do
      setup do
        # create waitlist with past time range
        wait_attrs      = [{:start_date => @yesterday, :end_date => @yesterday, :start_time_hours => "090000", :end_time_hours => "110000"}]
        @waitlist       = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
        @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }

      should "not find any available free time" do
        assert_equal [], @waitlist.available_free_time
      end

      should "not find any waitlist objects" do
        assert_equal [], @free_appt.waitlist
      end
    end

    context "where wait date overlaps free time" do
      context "and wait time does not overlap free time" do
        setup do
         # create waitlist with future time range
         wait_attrs      = [{:start_date => @tomorrow, :end_date => @tomorrow_plus1, :start_time_hours => "050000", :end_time_hours => "080000"}]
         @waitlist       = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
         @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
        end

        should_change("waitlist count", :by => 1) { Waitlist.count }

        should "not find any available free time" do
         assert_equal [], @waitlist.available_free_time
        end

        should "not find any waitlist objects" do
          assert_equal [], @free_appt.waitlist
        end
      end

      context "and wait time is bounded by free time" do
        setup do
          # create waitlist with future time range
          wait_attrs      = [{:start_date => @tomorrow, :end_date => @tomorrow_plus1, :start_time_hours => "090000", :end_time_hours => "110000"}]
          @waitlist       = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
          @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
        end

        should_change("waitlist count", :by => 1) { Waitlist.count }

        should "find available free time" do
          assert_equal [@free_appt], @waitlist.available_free_time
        end

        should "find waitlist objects" do
          assert_equal [@waitlist], @free_appt.waitlist
        end
      end

      context "and wait time is the same as free time" do
        setup do
          # create waitlist with future time range
          wait_attrs      = [{:start_date => @tomorrow, :end_date => @tomorrow_plus1, :start_time_hours => "080000", :end_time_hours => "120000"}]
          @waitlist       = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
          @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
        end

        should_change("waitlist count", :by => 1) { Waitlist.count }

        should "find available free time" do
          assert_equal [@free_appt], @waitlist.available_free_time
        end

        should "find waitlist objects" do
          assert_equal [@waitlist], @free_appt.waitlist
        end
      end
      
      context "and wait time overlaps free time start" do
        setup do
          # create waitlist with future time range
          wait_attrs      = [{:start_date => @tomorrow, :end_date => @tomorrow_plus1, :start_time_hours => "050000", :end_time_hours => "090000"}]
          @waitlist       = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
          @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
        end

        should_change("waitlist count", :by => 1) { Waitlist.count }

        should "find available free time" do
          assert_equal [@free_appt], @waitlist.available_free_time
        end

        should "find waitlist objects" do
          assert_equal [@waitlist], @free_appt.waitlist
        end
      end

      context "and wait time overlaps free time end" do
        setup do
          # create waitlist with future time range
          wait_attrs      = [{:start_date => @tomorrow, :end_date => @tomorrow_plus1, :start_time_hours => "113000", :end_time_hours => "133000"}]
          @waitlist       = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
          @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
        end

        should_change("waitlist count", :by => 1) { Waitlist.count }

        should "find available free time" do
          assert_equal [@free_appt], @waitlist.available_free_time
        end

        should "find waitlist objects" do
          assert_equal [@waitlist], @free_appt.waitlist
        end
      end
    end
  end

  context "create appointment waitlist" do
    setup do
      # create future free appoinment
      @tomorrow       = (Time.zone.now + 1.day).to_s(:appt_schedule_day) # e.g. 20081201
      @tomorrow_plus1 = (Time.zone.now + 2.days).to_s(:appt_schedule_day)
      @yesterday      = (Time.zone.now - 1.day).to_s(:appt_schedule_day)
      @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0800", :end_at => "1200"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service, :time_range => @time_range)
      assert @free_appt.valid?
      # create waitlist with future time range
      wait_attrs      = [{:start_date => @tomorrow, :end_date => @tomorrow_plus1, :start_time_hours => "080000", :end_time_hours => "120000"}]
      @waitlist       = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
      @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
      assert @waitlist.valid?
    end

    context "from free appointment" do
      setup do
        @appt_waitlists = AppointmentWaitlist.create_waitlist(@free_appt)
      end

      should_change("appointment waitlist", :by => 1) { AppointmentWaitlist.count }

      should "increment waitlist.appointment_waitlists_count" do
        assert_equal 1, @waitlist.reload.appointment_waitlists_count
      end

      should "increment appointment.appointment_waitlists_count" do
        assert_equal 1, @free_appt.reload.appointment_waitlists_count
      end

      context "then delete appointment" do
        setup do
          @free_appt.destroy
        end

        should_change("appointment waitlist", :by => -1) { AppointmentWaitlist.count }

        should "decrement waitlist.appointment_waitlists_count" do
          assert_equal 0, @waitlist.reload.appointment_waitlists_count
        end
      end
    end
    
    context "from waitlist" do
      setup do
        @appt_waitlists = AppointmentWaitlist.create_waitlist(@waitlist)
      end

      should_change("appointment waitlist", :by => 1) { AppointmentWaitlist.count }

      should "increment waitlist.appointment_waitlists_count" do
        assert_equal 1, @waitlist.reload.appointment_waitlists_count
      end

      should "increment appointment.appointment_waitlists_count" do
        assert_equal 1, @free_appt.reload.appointment_waitlists_count
      end

      context "then delete waitlist" do
        setup do
          @waitlist.destroy
        end

        should_change("appointment waitlist", :by => -1) { AppointmentWaitlist.count }

        should "decrement appointment.appointment_waitlists_count" do
          assert_equal 0, @free_appt.reload.appointment_waitlists_count
        end
      end
      
    end
  end
end