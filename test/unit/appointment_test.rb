require 'test/test_helper'
require 'test/factories'

class AppointmentTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :company_id
  should_validate_presence_of   :start_at
  should_validate_presence_of   :end_at
  should_validate_presence_of   :duration
  should_allow_values_for       :mark_as, "free", "work"
  
  should_belong_to              :company
  should_belong_to              :service
  should_belong_to              :provider
  should_belong_to              :customer
  should_have_one               :invoice
  should_belong_to              :location
  should_have_many              :capacity_slots
  
  should_belong_to              :recur_parent
  should_have_many              :recur_instances
  
  def setup
    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @anywhere       = Location.anywhere
    @provider       = Factory(:user, :name => "Provider")
    @company.user_providers.push(@provider)
    @company.reload
    @work_service   = Factory.build(:work_service, :name => "Work service", :price => 1.00)
    @company.services.push(@work_service)
    @work_service.user_providers.push(@provider)
    @free_service   = @company.free_service
    @customer       = Factory(:user)
  end
  
  context "create free appointment with mismatched duration and end_at values" do
    setup do
      @start_at_utc   = Time.zone.now.beginning_of_day.utc
      @end_at_utc     = @start_at_utc + 1.hour
      @start_at_day   = @start_at_utc.to_s(:appt_schedule_day)
      @daterange      = DateRange.parse_range(@start_at_day, @start_at_day)
      @appt           = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service,
                                                                     :start_at => @start_at_utc, :end_at => @end_at_utc, :duration => 120 * 60)
    end

    should_change("Appointment.count", :by => 1) { Appointment.count }

    should "have duration of 2 hours, and end_at time adjusted" do
      assert_equal 120 * 60, @appt.duration
      assert_equal 0, @appt.start_at.in_time_zone.hour
      assert_equal 2, @appt.end_at.in_time_zone.hour
    end

    should "have a valid uid" do
      assert !(@appt.uid.blank?)
      assert_match Regexp.new("[0-9]*-[0-9]*@walnutindustries.com"), @appt.uid
    end
  end
  
  context "create free appointment and test unscheduled time" do
    setup do
      @start_at_utc   = Time.zone.now.beginning_of_day.utc
      @end_at_utc     = @start_at_utc + 1.hour
      @start_at_day   = @start_at_utc.to_s(:appt_schedule_day)
      @daterange      = DateRange.parse_range(@start_at_day, @start_at_day)
      @appt           = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service, :start_at => @start_at_utc, :end_at => @end_at_utc)
    end
      
    should_change("Appointment.count", :by => 1) { Appointment.count }
    
    should "should not have a customer" do
      assert_equal nil, @appt.customer
    end
    
    should "have 1 unscheduled slot today for 23 hours starting at 1 am" do
      # build mapping of unscheduled time
      @unscheduled = AppointmentScheduler.find_unscheduled_time(@company, @anywhere, @provider, @daterange)
      assert_equal [@start_at_day], @unscheduled.keys
      assert_equal 1, @unscheduled[@start_at_day].size
      assert_equal 23.hours, @unscheduled[@start_at_day].first.duration
      assert_equal 1, @unscheduled[@start_at_day].first.start_at.in_time_zone.hour
      assert_equal 0, @unscheduled[@start_at_day].first.end_at.in_time_zone.hour
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
        assert_equal 0, CapacitySlot.count
      end
    end
  end
  
  context "create free appointment" do
    setup do
      # create free time from 10 am to 12 pm
      @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range     = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @free_appt      = AppointmentScheduler.create_free_appointment(@company, @provider, @free_service, :time_range => @time_range)
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
    
    context "and schedule work appointment without a customer" do
      should "raise exception" do
        assert_raise ArgumentError do
          @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @work_service.duration)
        end
      end
    end

    context "and schedule work appointment to test confirmation code" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @work_service.duration, @customer, @options)
        assert_valid @work_appt
      end

      should "have confirmation code of exactly 5 characters" do
        assert_equal 5, @work_appt.confirmation_code.size
        assert_match /([A-Z]|[0-9])+/, @work_appt.confirmation_code
      end
    end

    context "and schedule work appointment to test customer role" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, @work_service.duration, @customer, @options)
        assert_valid @work_appt
        @customer.reload
      end

      should "add 'user manager' role on user to customer" do
        assert_equal ['user manager'], @customer.roles_on(@customer).collect(&:name).sort
      end

      should "add 'company customer' role on company to customer" do
        assert_equal ['company customer'], @customer.roles_on(@company).collect(&:name).sort
      end
    end

    context "and schedule work appointment with a custom service duration" do
      setup do
        @customer   = Factory(:user)
        @options    = {:start_at => @free_appt.start_at}
        @work_appt  = AppointmentScheduler.create_work_appointment(@company, @provider, @work_service, 120 * 60, @customer, @options)
        assert_valid @work_appt
      end

      should "have work service with duration of 120 minutes" do
        assert_equal @work_service, @work_appt.service
        assert_equal 120 * 60, @work_appt.duration
        assert_equal 10, @work_appt.start_at.hour
        assert_equal 12, @work_appt.end_at.hour
      end

      context "then remove company" do
        setup do
          @company.destroy
        end

        should "have no companies or associated models" do
          assert_equal 0, Company.count
          assert_equal 0, Appointment.count
          assert_equal 0, Subscription.count
          assert_equal 0, CompanyProvider.count
          assert_equal 0, CapacitySlot.count
        end
      end
    end
  end
  
  # context "create waitlist appointment with a specific service provider" do
  #   setup do
  #     @johnny       = Factory(:user, :name => "Johnny")
  #     @company.user_providers.push(@johnny)
  #     @haircut      = Factory(:work_service, :name => "Haircut", :price => 1.00, :company => @company)
  #     @haircut.user_providers.push(@johnny)
  #     @customer     = Factory(:user)
  #     # build start, end date ranges in utc time
  #     @start_date   = Time.zone.now.utc.to_s(:appt_schedule_day)
  #     @end_date     = (Time.zone.now.utc + 7.days).to_s(:appt_schedule_day)
  #     @daterange    = DateRange.parse_range(@start_date, @end_date, :inclusive => false) # parsed as local time
  #     @options      = {:start_at => @daterange.start_at, :end_at => @daterange.end_at}
  #     @wait_appt    = AppointmentScheduler.create_waitlist_appointment(@company, @johnny, @haircut, @customer, @options)
  #   end
  # 
  #   should_change("Appointment.count", :by => 1) { Appointment.count }
  #   
  #   should "have a start date of today and end date in 1 week" do
  #     assert_equal @start_date, @wait_appt.start_at.utc.to_s(:appt_schedule_day) # utc format
  #     assert_equal @end_date, @wait_appt.end_at.utc.to_s(:appt_schedule_day) # utc format
  #   end
  #   
  #   should "have a time of day of 'anytime'" do
  #     assert_equal 0, @wait_appt.time_start_at
  #     assert_equal 86400, @wait_appt.time_end_at
  #   end
  # 
  #   should "add 'user manager' role on user to customer" do
  #     assert_equal ['user manager'], @customer.roles_on(@customer).collect(&:name).sort
  #   end
  # 
  #   should "add 'company customer' role on company to customer" do
  #     assert_equal ['company customer'], @customer.roles_on(@company).collect(&:name).sort
  #   end
  # 
  #   context "then remove company" do
  #     setup do
  #       @company.destroy
  #     end
  # 
  #     should "have no Companies or associated models" do
  #       assert_equal 0, Company.count
  #       assert_equal 0, Appointment.count
  #       assert_equal 0, Subscription.count
  #       assert_equal 0, CompanyProvider.count
  #       assert_equal 0, CapacitySlot.count
  #     end
  #   end
  # 
  # end

  # context "create waitlist appointment with any service provider" do
  #   setup do
  #     @johnny       = Factory(:user, :name => "Johnny")
  #     @company.user_providers.push(@johnny)
  #     @haircut      = Factory(:work_service, :name => "Haircut", :price => 1.00, :company => @company)
  #     @haircut.user_providers.push(@johnny)
  #     @customer     = Factory(:user)
  #     # build start, end date ranges in utc time
  #     @start_date   = Time.zone.now.utc.to_s(:appt_schedule_day)
  #     @end_date     = (Time.zone.now.utc + 7.days).to_s(:appt_schedule_day)
  #     @daterange    = DateRange.parse_range(@start_date, @end_date, :inclusive => false) # parsed as local time
  #     @options      = {:start_at => @daterange.start_at, :end_at => @daterange.end_at}
  #     @wait_appt    = AppointmentScheduler.create_waitlist_appointment(@company, nil, @haircut, @customer, @options)
  #     assert_valid @wait_appt
  #   end
  # 
  #   should_change("Appointment.count", :by => 1) { Appointment.count }
  # end
  
  context "create work appointment to check time overlap searching" do
    setup do
      # start at 2 pm, local time
      @start_at_local = Time.zone.now.beginning_of_day + 14.hours
      @start_at_utc   = @start_at_local.utc
      
      @appt = @company.appointments.create(:service => @work_service,
                                           :provider => @provider,
                                           :customer => @customer,
                                           :start_at => @start_at_local,
                                           :duration => @work_service.duration)
  
      assert_valid @appt
      @end_at_utc = @appt.end_at.utc
    end
    
    should "have time of day values based on start/end times in utc format" do
      assert_equal '', @appt.time
      assert_equal ((@start_at_utc.hour * 60) + @start_at_utc.min) * 60, @appt.time_start_at
      assert_equal ((@end_at_utc.hour * 60) + @end_at_utc.min) * 60, @appt.time_end_at
    end
    
    should "match afternoon and anytime time of day searches" do
      assert_equal [@appt], Appointment.time_overlap(Appointment.time_range("afternoon"))
      assert_equal [@appt], Appointment.time_overlap(Appointment.time_range("anytime"))
    end
    
    should "not match morning, evening, or invalid time of day searches" do
      assert_equal [], Appointment.time_overlap(Appointment.time_range("morning"))
      assert_equal [], Appointment.time_overlap(Appointment.time_range("evening"))
      assert_equal [], Appointment.time_overlap(Appointment.time_range("bogus"))
    end
  end
  
  context "create work appointment to check appointment roles and privileges" do
    setup do
      # initialize roles and privileges
      BadgesInit.roles_privileges

      # start at 2 pm, local time
      @start_at_local = Time.zone.now.beginning_of_day + 14.hours

      @appt = @company.appointments.create(:service => @work_service,
                                           :provider => @provider,
                                           :customer => @customer,
                                           :start_at => @start_at_local,
                                           :duration => @work_service.duration)
  
      assert_valid @appt
      @end_at_utc = @appt.end_at.utc
    end
    
    should "grant customer 'appointment manager' role on the appointment" do
      assert_equal ['appointment manager'], @customer.roles_on(@appt).collect(&:name).sort
    end
    
    should "grant provider 'appointment manager' role on the appointment" do
      assert_equal ['appointment manager'], @provider.roles_on(@appt).collect(&:name).sort
    end
  end
  
  context "build new appointment with time range attributes and am/pm times" do
    setup do
      @today = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @appt  = Appointment.new(:time_range => {:day => @today, :start_at => "1 pm", :end_at => "3 pm"})
    end
    
    should "have start time today at 1 pm local time" do
      assert_equal @today, @appt.start_at.to_s(:appt_schedule_day)
      assert_equal 13, @appt.start_at.hour
      assert_equal 0, @appt.start_at.min
    end
    
    should "have end time today at 3 pm local time" do
      assert_equal @today, @appt.end_at.to_s(:appt_schedule_day)
      assert_equal 15, @appt.end_at.hour
      assert_equal 0, @appt.end_at.min
    end
  end
  
  context "build new appointment with time range object and numeric times" do
    setup do
      @today      = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
      @time_range = TimeRange.new({:day => @today, :start_at => "1000", :end_at => "1200"})
      @appt       = Appointment.new(:time_range => @time_range)
    end
  
    should "have start time today at 10 am local time" do
      assert_equal @today, @appt.start_at.to_s(:appt_schedule_day)
      assert_equal 10, @appt.start_at.hour
      assert_equal 0, @appt.start_at.min
    end
    
    should "have end time today at noon local time" do
      assert_equal @today, @appt.end_at.to_s(:appt_schedule_day)
      assert_equal 12, @appt.end_at.hour
      assert_equal 0, @appt.end_at.min
    end
  end


  # Following tests are not in use
  
  # def test_time_of_day
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
  #   user      = Factory(:user)
  # 
  #   assert_difference('Appointment.count') do
  #     # create appointment at 2 pm
  #     appt = Appointment.create(:company => company,
  #                               :service => haircut,
  #                               :resource => johnny,
  #                               :user => user,
  #                               :start_at_string => "today 2 pm")
  # 
  #     assert appt.valid?
  #     assert_equal '', appt.when
  #     
  #     # check time of day values, which are utc
  #     assert_equal '', appt.time
  #     assert_equal (14*3600) - Time.zone.utc_offset, appt.time_start_at
  #     assert_equal (14*3600) + (30*60) - Time.zone.utc_offset, appt.time_end_at
  #     
  #     # test time searches, only afternoon and anytime should match
  #     assert_equal [], Appointment.time_overlap(Appointment.time_range("morning"))
  #     assert_equal [appt], Appointment.time_overlap(Appointment.time_range("afternoon"))
  #     assert_equal [], Appointment.time_overlap(Appointment.time_range("evening"))
  #     assert_equal [appt], Appointment.time_overlap(Appointment.time_range("anytime"))
  #     assert_equal [], Appointment.time_overlap(Appointment.time_range("bogus"))
  #   end
  # end
  
  # def test_overlap
  #   # clear database
  #   Appointment.delete_all
  #   
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
  #   customer  = Factory(:customer)
  #   
  #   # create appointment
  #   appt = Appointment.create(:company => company,
  #                             :service => haircut,
  #                             :resource => johnny,
  #                             :customer => customer,
  #                             :start_at_string => "today 2 pm")
  #   assert appt.valid?
  #   assert_equal '', appt.when
  #   assert_equal Chronic.parse("today 2 pm"), appt.start_at
  #   assert_equal Chronic.parse("today 2:30 pm"), appt.end_at
  # 
  #   # test appointment that matches exact start and end times
  #   appts = Appointment.overlap(Chronic.parse("today 2 pm").utc, Chronic.parse("today 2:30 pm").utc)
  #   assert_equal 1, appts.size
  #   assert_equal [appt], appts
  #   
  #   # test appointment that ends at start time
  #   appts = Appointment.overlap(Chronic.parse("today 1 pm").utc, Chronic.parse("today 2 pm").utc)
  #   assert_equal 0, appts.size
  # 
  #   # test appointment that starts at end time
  #   appts = Appointment.overlap(Chronic.parse("today 2:30 pm").utc, Chronic.parse("today 3 pm").utc)
  #   assert_equal 0, appts.size
  # 
  #   # test range that overlaps appointment start time
  #   appts = Appointment.overlap(Chronic.parse("today 1:30 pm").utc, Chronic.parse("today 2:15 pm").utc)
  #   assert_equal 1, appts.size
  #   assert_equal [appt], appts
  # 
  #   # test range that overlaps appointment end time
  #   appts = Appointment.overlap(Chronic.parse("today 2:15 pm").utc, Chronic.parse("today 2:45 pm").utc)
  #   assert_equal 1, appts.size
  #   assert_equal [appt], appts
  #   
  #   # test range that envelopes the appointment
  #   appts = Appointment.overlap(Chronic.parse("today 1:30 pm").utc, Chronic.parse("today 3 pm").utc)
  #   assert_equal 1, appts.size
  #   assert_equal [appt], appts
  # 
  #   # test range that is within the appointment
  #   appts = Appointment.overlap(Chronic.parse("today 2:05 pm").utc, Chronic.parse("today 2:15 pm").utc)
  #   assert_equal 1, appts.size
  #   assert_equal [appt], appts
  # end
  # 
  # def test_should_set_end_at_on_new_appointment
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
  #   customer  = Factory(:customer)
  #   
  #   assert_difference('Appointment.count') do
  #     appt = Appointment.create(:company => company,
  #                               :service => haircut,
  #                               :resource => johnny,
  #                               :customer => customer,
  #                               :start_at_string => "today 2 pm")
  #     assert appt.valid?
  #     assert_equal Chronic.parse("today 2 pm"), appt.start_at
  #     assert_equal Chronic.parse("today 2:30 pm").to_i, appt.end_at.to_i
  #   end
  # end
  # 
  # def test_should_not_allow_when_start_at_is_same_as_end_at
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   customer  = Factory(:customer)
  #   free      = company.services.free.first
  #   
  #   assert_no_difference('Appointment.count') do
  #     appt = Appointment.create(:company => company, 
  #                               :service => free,
  #                               :resource => johnny,
  #                               :customer => customer,
  #                               :start_at => "20080802000000",
  #                               :end_at =>   "20080802000000")
  #     assert !appt.valid?
  #     assert_match /Appointment start time/, appt.errors[:base]
  #   end
  # end
  # 
  # def test_should_not_allow_start_at_after_end_at
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   customer  = Factory(:customer)
  #   free      = company.services.free.first
  #   
  #   assert_no_difference('Appointment.count') do
  #     appt = Appointment.create(:company => company, 
  #                               :service => free,
  #                               :resource => johnny,
  #                               :customer => customer,
  #                               :start_at => "20080802000000",
  #                               :end_at =>   "20080801010000")
  #     assert !appt.valid?
  #     assert_match /Appointment start time/, appt.errors[:base]
  #   end
  # end
  # 
  # def test_should_set_duration
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   customer  = Factory(:customer)
  #   free      = company.services.free.first
  #   
  #   assert_difference('Appointment.count') do
  #     appt = Appointment.create(:company => company, 
  #                               :service => free,
  #                               :resource => johnny,
  #                               :customer => customer,
  #                               :start_at => "20080801000000",
  #                               :end_at =>   "20080801010000") # 1 hour
  #     assert appt.valid?
  #     assert_equal 60 * 60, appt.duration
  #   end
  # end
  # 
  # def test_should_create_and_search_waitlist
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
  #   customer  = Factory(:customer)
  #   
  #   # create waitlist appointment
  #   wait      = Appointment.create(:company => company,
  #                                  :mark_as => Appointment::WAIT,
  #                                  :service => haircut,
  #                                  :resource => johnny,
  #                                  :customer => customer,
  #                                  :when => "this week",
  #                                  :time => "morning")
  #   assert_valid wait
  #   wait.reload
  #   # appointment should be on waitlist
  #   assert wait.waitlist?
  #   assert_equal Appointment::WAIT, wait.mark_as
  #   # appointment should have a non-zero confirmation code
  #   assert_not_equal Appointment::CONFIRMATION_CODE_ZERO, wait.confirmation_code
  #   assert_equal haircut, wait.service
  #   assert_equal johnny, wait.resource
  #   assert_equal "upcoming", wait.state
  #   
  #   # assert_equal "", appt.start_at
  #   # assert_equal "", appt.end_at
  #   # time range should be entire day
  #   # assert_equal 0 - Time.zone.utc_offset, appt.time_start_at
  #   # assert_equal 24*3600 - Time.zone.utc_offset, appt.time_end_at
  #   
  #   # should find wait appointment on a blanket search
  #   assert_equal [wait], Appointment.wait
  #   
  #   # should find wait appointment on a morning search 
  #   assert_equal [wait], Appointment.wait.time_overlap(Appointment.time_range('morning'))
  # 
  #   # should find wait appointment on an anytiem search 
  #   assert_equal [wait], Appointment.wait.time_overlap(Appointment.time_range('anytime'))
  # 
  #   # should find no waitlist appointment on an afternoon search 
  #   assert_equal [], Appointment.wait.time_overlap(Appointment.time_range('afternoon'))
  # 
  #   # should find no waitlist appointment on an evening search 
  #   assert_equal [], Appointment.wait.time_overlap(Appointment.time_range('evening'))
  # 
  #   # should find no waitlist appointment on an invalid search 
  #   assert_equal [], Appointment.wait.time_overlap(Appointment.time_range('bogus'))
  #   
  #   # create free time from 8 am to noon
  #   free      = company.services.free.first
  #   start_at  = wait.start_at.beginning_of_day + 8.hours
  #   end_at    = start_at + 4.hours
  #   appt      = AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
  #   assert appt.valid?
  #   
  #   # should find waitlist overlap
  #   assert_equal [wait], appt.waitlist
  # 
  #   # create free time from noon to 5 pm
  #   start_at  = wait.start_at.beginning_of_day + 12.hours
  #   end_at    = start_at + 4.hours
  #   appt      = AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
  #   assert appt.valid?
  #   
  #   # should find no waitlist overlap
  #   assert_equal [], appt.waitlist
  # 
  #   # create free time from 1 am to 8 am
  #   start_at  = wait.start_at.beginning_of_day + 1.hour
  #   end_at    = start_at + 7.hours
  #   appt      = AppointmentScheduler.create_free_appointment(company, johnny, start_at, end_at)
  #   assert appt.valid?
  # 
  #   # should find no waitlist overlap
  #   assert_equal [], appt.waitlist
  # end
  # 
  # def test_should_validate_when_attribute
  #   appt = Appointment.new(:when => 'bogus')
  #   assert !appt.valid?
  #   # should have an error for the when attribute
  #   assert_equal "When is invalid", appt.errors[:base]
  # end
  # 
  # def test_should_validate_time_attribute
  #   appt = Appointment.new(:time => 'bogus')
  #   assert !appt.valid?
  #   # should have an error for the time attribute
  #   assert_equal "Time is invalid", appt.errors[:base]
  # end
  # 
  # 
  # def test_should_build_appointment_with_location
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
  #   location  = Factory(:location)
  #   company.locations = Array(location)
  #   
  #   assert_difference('Appointment.count', 1) do
  #     appt = Appointment.new(:company => company, 
  #                            :service => haircut,
  #                            :resource => johnny,
  #                            :customer_attributes => {"name" => "Customer 1", "email" => "customer1@peanut.com", "phone" => "4085551212"},
  #                            :start_at_string => "today 2 pm",
  #                            :location_id => location.id.to_s)
  #     assert appt.valid?
  #     appt.save
  #     appt.reload
  #     assert appt.locations == Array(location)
  #   end
  # end
  # 
  # def test_should_build_appointment_with_location_anywhere
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
  #   
  #   assert_difference('Appointment.count', 1) do
  #     appt = Appointment.new(:company => company, 
  #                            :service => haircut,
  #                            :resource => johnny,
  #                            :customer_attributes => {"name" => "Customer 1", "email" => "customer1@peanut.com", "phone" => "4085551212"},
  #                            :start_at_string => "today 2 pm",
  #                            :location_id => Location.anywhere.id)
  #     assert appt.valid?
  #     appt.save
  #     appt.reload
  #     # appointment should have no locations
  #     assert appt.locations == []
  #   end
  # end
  # 
  # def test_should_build_customer_association
  #   company = Factory(:company)
  #   johnny  = Factory(:person, :name => "Johnny", :companies => [company])
  #   haircut = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
  #   
  #   # should create a new customer when building the new appointment
  #   assert_difference('Customer.count', 1) do
  #     appt = Appointment.new(:company => company, 
  #                            :service => haircut,
  #                            :resource => johnny,
  #                            :customer_attributes => {"name" => "Customer 1", "email" => "customer1@peanut.com", "phone" => "4085551212"},
  #                            :start_at_string => "today 2 pm")
  #   
  #     assert appt.valid?
  #   end
  #   
  #   # should use the existing customer when building the new appointment
  #   assert_no_difference('Customer.count') do
  #     appt = Appointment.new(:company => company, 
  #                            :service => haircut,
  #                            :resource => johnny,
  #                            :customer_attributes => {"name" => "Customer 1", "email" => "customer1@peanut.com", "phone" => "4085551212"},
  #                            :start_at_string => "today 2 pm")
  #   
  #     assert appt.valid?
  #   end
  # end  
  #       
  # def test_confirmation_code
  #   company   = Factory(:company)
  #   johnny    = Factory(:person, :name => "Johnny", :companies => [company])
  #   customer  = Factory(:customer)
  #   free      = company.services.free.first
  #   
  #   appt = Appointment.create(:company => company, 
  #                             :service => free,
  #                             :resource => johnny,
  #                             :customer => customer,
  #                             :start_at => "20080801000000",
  #                             :end_at =>   "20080801010000") # 1 hour
  #   assert appt.valid?
  #   
  #   # confirmation code should be 5 characters
  #   assert_equal 5, appt.confirmation_code.size
  #   assert_match /([A-Z]|[0-9])+/, appt.confirmation_code
  # 
  #   # create another appointment
  #   appt2 = Appointment.create(:company => company, 
  #                              :service => free,
  #                              :resource => johnny,
  #                              :customer => customer,
  #                              :start_at => "20080901000000",
  #                              :end_at =>   "20080901010000") # 1 hour
  #   assert appt2.valid?
  # 
  #   # confirmation code should be 5 characters
  #   assert_equal 5, appt2.confirmation_code.size
  #   assert_match /([A-Z]|[0-9])+/, appt2.confirmation_code
  #   # confirmation code should the same for free appointments
  #   assert_equal appt.confirmation_code, appt2.confirmation_code
  # end
  # 
  # def test_should_narrow_by_morning
  #   # build appointment from 5:30am - 12:30pm
  #   appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
  #   
  #   # request morning appointments, narraw from 8am - 12pm
  #   appointment.narrow_by_time_of_day!('morning')
  #   assert_equal  Time.now.beginning_of_day + 8.hours, appointment.start_at
  #   assert_equal  Time.now.beginning_of_day + 12.hours, appointment.end_at
  # end
  # 
  # def test_should_narrow_by_afternoon_to_empty
  #   # build appointment from 5:30am - 12pm
  #   appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
  #   
  #   # request afternoon appointments, narrow to empty
  #   appointment.narrow_by_time_of_day!('afternoon')
  #   assert_equal nil, appointment.start_at
  #   assert_equal nil, appointment.end_at
  #   assert_equal 0 * 60, appointment.duration
  # 
  #   # build appointment from 5:30am - 11:30pm
  #   appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 11:30 am"))
  #   
  #   # request afternoon appointments, narrow to empty
  #   appointment.narrow_by_time_of_day!('afternoon')
  #   assert_equal nil, appointment.start_at
  #   assert_equal nil, appointment.end_at
  #   assert_equal 0 * 60, appointment.duration
  # end
  # 
  # def test_should_narrow_by_evening_to_empty
  #   # build appointment from 5:30am - 12pm
  #   appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
  #   
  #   # request evening appointments, narrow to empty
  #   appointment.narrow_by_time_of_day!('evening')
  #   assert_equal nil, appointment.start_at
  #   assert_equal nil, appointment.end_at
  #   assert_equal 0 * 60, appointment.duration
  # end
  # 
  # def test_narrow_by_anytime
  #   # build appointment from 5:30am - 12pm
  #   appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
  #   
  #   # request anytime appointments
  #   appointment.narrow_by_time_of_day!('anytime')
  #   assert_equal  Time.now.beginning_of_day + 5.hours + 30.minutes, appointment.start_at
  #   assert_equal  Time.now.beginning_of_day + 12.hours, appointment.end_at
  # end
  # 
  # def test_should_narrow_by_bogus_to_empty
  #   # build appointment from 5:30am - 12pm
  #   appointment = Appointment.new(:start_at => Chronic.parse("today 5:30 am"), :end_at => Chronic.parse("today 12 pm"))
  #   
  #   # request an invalid time of day, narrow to empty
  #   appointment.narrow_by_time_of_day!('bogus')
  #   assert_equal nil, appointment.start_at
  #   assert_equal nil, appointment.end_at
  # end
  
  
  #
  # Recurrence Tests
  #
  
  context "create one invalid recurring free appointment (private, no service)" do
    setup do
      @start_at       = Time.zone.now.beginning_of_day.utc
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 8.weeks
      # Recur 2 and 4 days from now
      @recur_days     = "#{ical_days([@start_at + 2.days, @start_at + 4.days])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Appointment.new(:company => @company, :customer => @customer, :provider => @provider,
                                        :start_at => @start_at, :end_at => @end_at, :public => false,
                                        :mark_as => "free", :recur_rule => @recur_rule,
                                        :description => "This is the recurrence description")
    end
    
    should "not be valid" do
      assert_false @recurrence.valid?
    end
    
    should "create no appointments or capacity slots" do
      assert_equal 0, Appointment.count
      assert_equal 0, CapacitySlot.count
    end
  
  end
    
  context "create one invalid recurring free appointment (private, no provider)" do
    setup do
      @start_at       = Time.zone.now.beginning_of_day.utc
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 8.weeks
      # Recur 2 and 4 days from now
      @recur_days     = "#{ical_days([(@start_at + 2.days), (@start_at + 4.days)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Appointment.new(:company => @company, :customer => @customer, :service => @free_service,
                                        :start_at => @start_at, :end_at => @end_at, :public => false,
                                        :mark_as => "free", :recur_rule => @recur_rule, :description => "This is the recurrence description")
    end
    
    should "not be valid" do
      assert_false @recurrence.valid?
    end
  
    should "create no appointments or capacity slots" do
      assert_equal 0, Appointment.count
      assert_equal 0, CapacitySlot.count
    end
  end
    
  context "create one valid recurring free private appointment" do
    setup do
      @start_at       = Time.zone.now.beginning_of_day
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 8.weeks
      @recur_days     = "#{ical_days([@start_at.utc, (@start_at + 4.days).utc])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Appointment.create(:company => @company, :customer => @customer, :provider => @provider,
                                          :service => @free_service, :start_at => @start_at, :end_at => @end_at, :mark_as => "free",
                                          :recur_rule => @recur_rule, :description => "This is the recurrence description")
      assert_valid @recurrence
    end
    
    should_change("Appointment.count", :by => 1) { Appointment.count }
    should_change("CapacitySlot.count", :by => 1) { CapacitySlot.count }

    should_not_change("Appointment.public.count") { Appointment.public.count }

    should "have duration of 2 hours and start at 00:00 and finish at 02:00" do
      assert_equal 2.hours, @recurrence.duration
      assert_equal 0, @recurrence.start_at.in_time_zone.hour
      assert_equal 2, @recurrence.end_at.in_time_zone.hour
    end

    should "have a valid uid" do
      assert !(@recurrence.uid.blank?)
      assert_match Regexp.new("[0-9]+-[0-9]+@walnutindustries.com"), @recurrence.uid
    end

    context "then expand the recurring appointment" do
      setup do 
        @recurrence.expand_recurrence(@end_at, @start_at + 4.weeks - 1.hour)
      end

      should_change("Appointment.count", :by => 7) { Appointment.count }
      should_change("CapacitySlot.count", :by => 7) { CapacitySlot.count }

      should_not_change("Appointment.public.count") { Appointment.public.count }

      should "have instances with duration of 2 hours and start at 00:00 and finish at 02:00" do
        @recurrence.recur_instances.each do |a|
          assert_equal 2.hours, a.duration
          assert_equal 0, a.start_at.in_time_zone.hour
          assert_equal 2, a.end_at.in_time_zone.hour
        end
      end

      should "have instances with same attributes as recurrence" do
        @recurrence.recur_instances.each do |a|
          assert_equal @recurrence.company_id, a.company_id
          assert_equal @recurrence.service_id, a.service_id
          assert_equal @recurrence.location_id, a.location_id
          assert_equal @recurrence.provider_id, a.provider_id
          assert_equal @recurrence.customer_id, a.customer_id
          assert_equal @recurrence.mark_as, a.mark_as
          assert_equal @recurrence.confirmation_code, a.confirmation_code
          assert_equal @recurrence.uid, a.uid
          assert_equal @recurrence.description, a.description
          assert_equal @recurrence.public, a.public
          assert_equal @recurrence.name, a.name
          assert_equal @recurrence.popularity, a.popularity
          assert_equal @recurrence.url, a.url
          assert_equal @recurrence.source_type, a.source_type
          assert_equal @recurrence.source_id, a.source_id
        end
      end

      context "then delete the recurrence" do
         setup do
           @recur_instances = @recurrence.recur_instances
           @recurrence.destroy
         end

         should_change("Appointment.count", :by => -1) { Appointment.count }
         
         should "have 7 instances with no recurrence parent" do
           assert_equal 7, @recur_instances.count
           @recur_instances.each do |i|
             assert_nil i.recur_parent
           end
         end

      end

      context "then change the recurrence description" do
        setup do
          @recurrence.description = "This is a changed recurring description"
          @recurrence.save
        end

        should_not_change("Appointment.count") { Appointment.count }

        should "change appointments' description" do
          @recurrence.recur_instances.each do |a|
            assert_equal "This is a changed recurring description", a.description
          end
        end

      end

      context "then change end time and duration of the recurrence" do
        setup do
          @recurrence.end_at = @recurrence.start_at + 3.hours
          @recurrence.duration = 3.hours / 60
          @recurrence.save
          @recurrence.reload
        end

        should_not_change("Appointment.count") { Appointment.count }

        should "change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 180 * 60, a.duration
            assert_equal 0, a.start_at.in_time_zone.hour
            assert_equal 3, a.end_at.in_time_zone.hour
          end
        end

      end

      context "then change the recurrence rule to 3 per week" do
        setup do
          @recur_days            = "#{ical_days([@start_at, @start_at + 3.days, @start_at + 5.days])}"
          @recur_rule            = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
          @recurrence.recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
          @recurrence.save
          @recurrence.reload
        end

        should_change("Appointment.count", :by => 4) { Appointment.count }

        should "not change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 120 * 60, a.duration
            assert_equal 0, a.start_at.in_time_zone.hour
            assert_equal 2, a.end_at.in_time_zone.hour
          end
        end

      end

      context "then change the recurrence rule to 3 per week and change end time" do
        setup do
          @recurrence.end_at     = @recurrence.start_at + 3.hours
          @recurrence.duration   = 3.hours / 60
          @recur_days            = "#{ical_days([@start_at, @start_at + 3.days, @start_at + 5.days])}"
          @recurrence.recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
          @recurrence.save
          @recurrence.reload
        end

        should_change("Appointment.count", :by => 4) { Appointment.count }

        should "change appointments' end time and duration" do
          @recurrence.recur_instances.each do |a|
            assert_equal 180 * 60, a.duration
            assert_equal 0, a.start_at.in_time_zone.hour
            assert_equal 3, a.end_at.in_time_zone.hour
          end
        end

      end

      context "then create a second recurrence" do
        setup do
          @start_at       = Time.zone.now.beginning_of_day.utc
          @end_at         = @start_at + 30.minutes
          @end_recurrence = @start_at + 8.weeks
          @recur_days     = "#{ical_days([(@start_at + 1.day), (@start_at + 5.days)])}"
          @recur_rule     = "FREQ=WEEKLY;INTERVAL=2;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
          @recurrence2    = Appointment.create(:company => @company, :customer => @customer,  :provider => @provider,
                                              :service => @free_service, :start_at => @start_at, :end_at => @end_at, :mark_as => "free",
                                              :recur_rule => @recur_rule, :description => "This is the 2nd recurrence description")
          assert_valid @recurrence2
          appointments    = @recurrence2.expand_recurrence(@start_at, @start_at + 4.weeks - 1.hour)
        end

        should_change("Appointment.count", :by => 5) { Appointment.count }

        should "have duration of 30 minutes" do
          @recurrence2.recur_instances.each do |a|
            assert_equal 30 * 60, a.duration
            assert_equal 0, a.start_at.in_time_zone.hour
            assert_equal 0, a.end_at.in_time_zone.hour
            assert_equal 30, a.end_at.min
          end
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
            assert_equal 0, CapacitySlot.count
          end
        end
      end

      context "delete the second recurrence" do
        setup do
          setup do
            @recurrence2.destroy
          end

          should_change("Appointment.count", :by => -5) { Appointment.count }
        end

      end

      context "then search for available time" do

      end


      context "then schedule an overlapping available appointment" do

      end


    end
  
  end
  
  context "create an available appointment" do
    
    context "and then create a recurring available appointment overlapping the existing available appointment" do
      
    end
  
  end
  
  context "create a recurring free public appointment ending in 13 days" do
    setup do
      @start_at       = Time.zone.now.beginning_of_day.utc
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 13.days
      @recur_days     = "#{ical_days([(@start_at)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence     = Appointment.create(:company => @company, :start_at => @start_at, :end_at => @end_at, :mark_as => "free",
                                          :recur_rule => @recur_rule, :name => "Happy Hour!", 
                                          :description => "$2 beers, $3 well drinks", :public => true)
      assert_valid @recurrence
      @recurrence.expand_recurrence(@end_at, @start_at + 4.weeks)
    end
    
    should_change("Appointment.count", :by => 2) { Appointment.count }
    
    should_change("Appointment.public.count", :by => 2) { Appointment.public.count }
  
  end
  
  context "create a recurring free public appointment with no end instantiating 3 instances" do
    setup do
      @start_at   = Time.zone.now.beginning_of_day.utc
      @end_at     = @start_at + 2.hours
      @recur_days = "#{ical_days([(@start_at + 3.days)])}"
      @recur_rule = "FREQ=WEEKLY;BYDAY=#{@recur_days}"
      @recurrence = Appointment.create(:company => @company, :start_at => @start_at, :end_at => @end_at, :mark_as => "free",
                                      :recur_rule => @recur_rule, :name => "Happy Hour!", 
                                      :description => "$2 beers, $3 well drinks", :public => true)
      assert_valid @recurrence
      @appointments   = @recurrence.expand_recurrence(@start_at, @start_at + 4.weeks, 3)
    end
    
    should_change("Appointment.count", :by => 4) { Appointment.count }
    
    should_change("Appointment.public.count", :by => 4) { Appointment.public.count }
    
    should "have 3 appointments returned from expand_recurrence" do
      assert_equal  3, @appointments.size
    end
  
  end
  
  context "create a recurring free public appointment which ends in the past" do
    setup do
      @now            = Time.zone.now.beginning_of_day.utc
      @start_at       = @now - 6.months
      @end_at         = @start_at + 2.hours
      @end_recurrence = @start_at + 4.weeks
      @recur_days     = "#{ical_days([(@start_at + 2.days)])}"
      @recur_rule     = "FREQ=WEEKLY;BYDAY=#{@recur_days};UNTIL=#{@end_recurrence.utc.strftime("%Y%m%dT%H%M%SZ")}"
      @recurrence = Appointment.create(:company => @company, :start_at => @start_at, :end_at => @end_at, :mark_as => "free",
                                      :recur_rule => @recur_rule, :name => "Happy Hour!", 
                                      :description => "$2 beers, $3 well drinks", :public => true)
      assert_valid @recurrence
      @appointments   = @recurrence.expand_recurrence(@now, @now + 4.weeks)
    end
  
    should_change("Appointment.count", :by => 1) { Appointment.count }
  
  end
  
end
