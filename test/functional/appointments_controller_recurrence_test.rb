require 'test/test_helper'

class AppointmentsControllerTest < ActionController::TestCase

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company, with 2 managers
    @owner        = Factory(:user, :name => "Owner")
    @owner.email_addresses.create(:address => 'owner@walnutcalendar.com')
    @manager      = Factory(:user, :name => "Manager")
    @manager.email_addresses.create(:address => 'manager@walnutcalendar.com')
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    @manager.grant_role('company manager', @company)
    # create providers, with email addresses
    @johnny       = Factory(:user, :name => "Johnny")
    @johnny.email_addresses.create(:address => 'johnny@walnutcalendar.com')
    @company.user_providers.push(@johnny)
    @mary         = Factory(:user, :name => "Mary")
    @mary.email_addresses.create(:address => 'mary@walnutcalendar.com')
    @company.user_providers.push(@mary)
    # create a work service, and assign johnny and mary as service providers
    @haircut      = Factory.build(:work_service, :duration => 30.minutes, :name => "Haircut", :price => 1.00)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    @haircut.user_providers.push(@mary)
    @blowdry      = Factory.build(:work_service, :duration => 30.minutes, :name => "Blow Dry", :price => 1.00)
    @company.services.push(@blowdry)
    @blowdry.user_providers.push(@johnny)
    @blowdry.user_providers.push(@mary)
    @johnny.reload
    @mary.reload
    @company.reload
    # get company free service
    @free_service = @company.free_service
    # create a customer, with an email address and phone number
    @customer     = Factory(:user, :name => "Customer")
    @customer.email_addresses.create(:address => 'customer@walnutcalendar.com')
    @customer.phone_numbers.create(:name => 'Mobile', :address => '3129999999')
    # stub current company
    @controller.stubs(:current_company).returns(@company)
    # set the request hostname
    @request.host = "www.walnutcalendar.com"
  end

  context "create weekly schedule" do
    setup do
      @now = Time.zone.now
      @recur_until = @now + 4.weeks + 1.hour 
    end

    context "with no end date" do
      setup do
        # have johnny create free appointments on his calendar
        @controller.stubs(:current_user).returns(@johnny)
        @rule = "freq=weekly;byday=mo,tu;dstart=#{@now.to_s(:appt_schedule_day)};tstart=090000;tend=110000"
        post :create_weekly,
             {:rules => @rule, :provider_type => "users", :provider_id => @johnny.id}
             # {:freq => 'weekly', :byday => 'mo,tu', :dstart => @now.to_s(:appt_schedule_day), :tstart => "090000", :tend => "110000",
             #  :until => '', :provider_type => "users", :provider_id => "#{@johnny.id}"}
      end

      should_change("Appointment.recurring.count", :by => 1) { Appointment.recurring.count }
      should_change("Appointment.count", :by => 1) { Appointment.count }

      should_assign_to(:freq) { "WEEKLY" }
      should_assign_to(:byday) { "MO,TU" }
      should_assign_to(:dtstart) { "#{@now.to_s(:appt_schedule_day)}T090000" }
      should_assign_to(:dtend) { "#{@now.to_s(:appt_schedule_day)}T110000" }
      should_assign_to(:recur_rule) { "FREQ=WEEKLY;BYDAY=MO,TU" }
      should_assign_to(:provider) { @johnny }

      should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }

      context "and create a conflicting weekly schedule" do
        setup do
          @controller.stubs(:current_user).returns(@johnny)
          @rule = "freq=weekly;byday=mo,tu;dstart=#{@now.to_s(:appt_schedule_day)};tstart=100000;tend=120000"
          post :create_weekly,
               {:rules => @rule, :provider_type => "users", :provider_id => @johnny.id}
               # {:freq => 'weekly', :byday => 'mo,tu', :dstart => @now.to_s(:appt_schedule_day), :tstart => "100000", :tend => "120000",
               #  :until => '', :provider_type => "users", :provider_id => "#{@johnny.id}"}
        end

        should_change("Appointment.recurring.count", :by => 1) { Appointment.recurring.count }
        should_change("Appointment.count", :by => 1) { Appointment.count }
      end
    end

    context "with an end date" do
      setup do
        # have johnny create free appointments on his calendar
        @controller.stubs(:current_user).returns(@johnny)
        post :create_weekly,
             {:rules => "freq=weekly;byday=mo,tu;dstart=#{@now.to_s(:appt_schedule_day)};tstart=090000;tend=110000;until=#{@recur_until.to_s(:appt_schedule_day)}",
              :provider_type => "users", :provider_id => @johnny.id}
             # {:freq => 'weekly', :byday => 'mo,tu', :dstart => @now.to_s(:appt_schedule_day), :tstart => "090000", :tend => "110000",
             #  :until => @recur_until.to_s(:appt_schedule_day), :provider_type => "users", :provider_id => "#{@johnny.id}"}
        Delayed::Job.work_off
      end

      # should have a recurring appointment plus 2 appointments each week for the next 4 weeks = 9 total
      should_change("Appointment.recurring.count", :by => 1) { Appointment.recurring.count }
      should_change("Appointment.count", :by => 9) { Appointment.count }

      should_assign_to(:freq) { "WEEKLY" }
      should_assign_to(:byday) { "MO,TU" }
      should_assign_to(:dtstart) { "#{@now.to_s(:appt_schedule_day)}T090000" }
      should_assign_to(:dtend) { "#{@now.to_s(:appt_schedule_day)}T110000" }
      should_assign_to(:recur_rule) { "FREQ=WEEKLY;BYDAY=MO,TU;UNTIL=#{@recur_until.to_s(:appt_schedule_day)}T000000Z" }
      should_assign_to(:provider) { @johnny }

      should_redirect_to("user calendar path" ) { "/users/#{@johnny.id}/calendar" }

      context "and change the weekly schedule" do
        setup do
          @weekly_appt = Appointment.recurring.first
          put :update_weekly,
              {:rules => "freq=weekly;byday=mo,tu,fr;dstart=#{@now.to_s(:appt_schedule_day)};tstart=110000;tend=130000;until=#{@recur_until.to_s(:appt_schedule_day)}",
               :id => @weekly_appt.id, :provider_type => "users", :provider_id => @johnny.id}
          Delayed::Job.work_off
          @weekly_appt.reload
          # we are adding friday to the schedule, check if today is friday
          if Time.zone.now.wday == 5
            # today should not be added
            @should_add = 3
          else
            @should_add = 4
          end
        end

        # should have 1 additional appointment each week for the next 4 weeks = 4 additional
        should_not_change("Appointment.recurring.count") { Appointment.recurring.count }
        should_change("Appointment.count", :by => @should_add) { Appointment.count }

        should "change weekly appointment attributes" do
          assert_equal 11, @weekly_appt.start_at.hour.to_i
          assert_equal 13, @weekly_appt.end_at.hour.to_i
        end

        should_assign_to(:freq) { "WEEKLY" }
        should_assign_to(:byday) { "MO,TU,FR" }
        should_assign_to(:dtstart) { "#{@now.to_s(:appt_schedule_day)}T110000" }
        should_assign_to(:dtend) { "#{@now.to_s(:appt_schedule_day)}T130000" }
        should_assign_to(:recur_rule) { "FREQ=WEEKLY;BYDAY=MO,TU,FR;UNTIL=#{@recur_until.to_s(:appt_schedule_day)}T000000Z" }
        should_assign_to(:provider) { @johnny }

        should_redirect_to("user show weekly schedule path" ) { "/users/#{@johnny.id}/calendar/weekly" }
      end
      
      context "and cancel the weekly schedule" do
        setup do
          @weekly_appt = Appointment.recurring.first
          get :cancel, :id => @weekly_appt.id, :series => 1
        end

        should "change appointment state to canceled" do
          assert_equal "canceled", @weekly_appt.reload.state
        end

        should_not_change("appointment count") { Appointment.count }
        # should remove 9 capacity slots for 9 appointments
        should_change("capacity slot count", :by => -9) { CapacitySlot.count }
      end
    end

    context "with 2 recur rules for 1 day each" do
      setup do
        # have johnny create free appointments on his calendar
        @controller.stubs(:current_user).returns(@johnny)
        @rules = ["freq=weekly;byday=mo;dstart=#{@now.to_s(:appt_schedule_day)};tstart=090000;tend=110000",
                  "freq=weekly;byday=tu;dstart=#{@now.to_s(:appt_schedule_day)};tstart=090000;tend=110000"]
        post :create_weekly,
             {:rules => @rules.join("|"), :provider_type => "users", :provider_id => @johnny.id}
      end

      # these values should be the last rule in the list
      should_assign_to(:freq) { "WEEKLY" }
      should_assign_to(:byday) { "TU" }
      should_assign_to(:dtstart) { "#{@now.to_s(:appt_schedule_day)}T090000" }
      should_assign_to(:dtend) { "#{@now.to_s(:appt_schedule_day)}T110000" }
      should_assign_to(:recur_rule) { "FREQ=WEEKLY;BYDAY=TU" }
      should_assign_to(:provider) { @johnny }

      should_change("Appointment.recurring.count", :by => 2) { Appointment.recurring.count }
      should_change("Appointment.count", :by => 2) { Appointment.count }
    end
  end

end