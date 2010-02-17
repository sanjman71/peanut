require 'test/test_helper'

class TasksControllerTest < ActionController::TestCase

  should_route :get, '/tasks/appointments/reminders/2-days', :controller => 'tasks', :action => 'appointment_reminders', :time_span => '2-days'
  should_route :get, '/tasks/appointments/messages/whenever', :controller => 'tasks', :action => 'appointment_messages', :time_span => 'whenever'
  should_route :get, '/tasks/users/messages/whenever', :controller => 'tasks', :action => 'user_messages', :time_span => 'whenever'
  should_route :get, '/tasks/schedules/messages/daily', :controller => 'tasks', :action => 'schedule_messages', :time_span => 'daily'
  should_route :get, '/tasks/expand_all_recurrences', :controller => 'tasks', :action => 'expand_all_recurrences'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner          = Factory(:user, :name => "Owner")
    @provider       = Factory(:user, :name => "Provider")
    @provider_email = @provider.email_addresses.create(:address => "provider@walnut.com")
    @customer       = Factory(:user, :name => "Customer", :password => 'customer', :password_confirmation => 'customer')
    @customer_email = @customer.email_addresses.create(:address => "customer@walnut.com")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    # make owner the company manager
    @owner.grant_role('company manager', @company)
    @provider.grant_role('company provider', @provider)
    # add company providers
    @company.user_providers.push(@owner)
    @company.user_providers.push(@provider)
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
    # create appointment(s)
    create_appointment_in_the_next_day
  end

  def create_appointment_in_the_next_day
    # create work service
    @work_service   = Factory.build(:work_service, :name => "Work service", :price => 1.00)
    @company.services.push(@work_service)
    @work_service.user_providers.push(@provider)
    @free_service   = @company.free_service
    # create free time tomorrow from midnight to 2 am
    @today          = Time.zone.now.to_s(:appt_schedule_day) # e.g. 20081201
    @tomorrow       = (Time.zone.now+1.day).to_s(:appt_schedule_day)
    @time_range     = TimeRange.new({:day => @tomorrow, :start_at => "0000", :end_at => "0200"})
    @free_appt      = AppointmentScheduler.create_free_appointment(@company, Location.anywhere, @provider, :time_range => @time_range)
    @options        = {:start_at => @free_appt.start_at}
    @work_appt      = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @work_service, @work_service.duration, @customer, @options)
    assert @work_appt.valid?
  end

  context "appointment reminders" do
    context "without 'manage site' privilege" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :appointment_reminders, :time_span => '1-day'
      end

      should_redirect_to('unauthorized_path') { unauthorized_path }
    end

    context "for appointment with customer reminder on" do
      setup do
        @owner.grant_role('admin')
        @controller.stubs(:current_user).returns(@owner)
        get :appointment_reminders, :time_span => '1-day'
      end

      should_assign_to(:number) { '1' }
      should_assign_to(:units) { 'day' }
      should_assign_to(:appointments) { [@work_appt] }
      should_assign_to(:messages)

      should_change("Message.count", :by => 1) { Message.count }
      should_change("delayed job count", :by => 1) { Delayed::Job.count }

      should "add appointment message topic tag" do
        assert_equal ['reminder'], @work_appt.message_topics.collect(&:tag)
      end

      should "set message preferences template" do
        @message = assigns(:messages).first
        assert_equal :appointment_reminder, @message.reload.preferences[:template]
      end

      should "set message preferences provider" do
        @message = assigns(:messages).first
        assert_equal "Provider", @message.reload.preferences[:provider]
      end

      should "set message preferences service" do
        @message = assigns(:messages).first
        assert_equal "Work Service", @message.reload.preferences[:service]
      end

      should "set message preferences customer" do
        @message = assigns(:messages).first
        assert_equal "Customer", @message.reload.preferences[:customer]
      end

      should "set message preferences when" do
        @message = assigns(:messages).first
        assert @message.reload.preferences[:when]
      end

      should_respond_with :success
      should_render_template 'tasks/appointment_reminders.html.haml'
    end

    context "for appointment with customer reminder on, and reminder already sent" do
      setup do
        # send appointment reminder
        @message = MessageComposeAppointment.reminder(@work_appt.reload)
        @owner.grant_role('admin')
        @controller.stubs(:current_user).returns(@owner)
        get :appointment_reminders, :time_span => '1-day'
      end
    
      should_assign_to(:number) { '1' }
      should_assign_to(:units) { 'day' }
      should_assign_to(:appointments) { [@work_appt] }
      should_assign_to(:messages) { [] }

      should_respond_with :success
      should_render_template 'tasks/appointment_reminders.html.haml'
    end

    context "for appointment with customer reminder off" do
      setup do
        @owner.grant_role('admin')
        @work_appt.preferences[:reminder_customer] = '0'
        @work_appt.save
        @controller.stubs(:current_user).returns(@owner)
        get :appointment_reminders, :time_span => '1-day'
      end

      should_assign_to(:number) { '1' }
      should_assign_to(:units) { 'day' }
      should_assign_to(:appointments) { [@work_appt] }
      should_assign_to(:messages) { [] }

      should_not_change("Message.count") { Message.count }
      should_not_change("delayed job count") { Delayed::Job.count }

      should_respond_with :success
      should_render_template 'tasks/appointment_reminders.html.haml'
    end
  end

  context "schedules" do
    setup do
      @provider.preferences[:provider_email_daily_schedule] = '1'
      @provider.save
      @controller.stubs(:current_user).returns(@owner)
      get :schedule_messages, :time_span => 'daily', :token => AUTH_TOKEN_INSTANCE
    end

    should_assign_to(:providers) { [@provider] }

    should_change("delayed job count", :by => 1) { Delayed::Job.count }

    should_respond_with :success
    should_render_template 'tasks/schedule_messages.html.haml'
  end
end