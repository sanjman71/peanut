class TasksController < ApplicationController
  
  # managers only for now
  privilege_required      'manage site', :on => :current_company, :unless => :auth_token?

  # GET /tasks
  def index
    respond_to do |format|
      format.html
    end
  end

  # GET /tasks/appointments/messages/whenever
  # List all appointment messages
  def appointment_messages
    # find appointments with messages
    @appointments = current_company.appointments.work.all(:include => :message_topics)
    @messages     = []
    @timeline     = ''

    @title        = "Tasks - Appointment Messages"

    respond_to do |format|
      format.html { render(:action => 'appointment_reminders')}
    end
  end

  # GET /tasks/appointments/reminders/2-days
  # GET /tasks/appointments/reminders/7-hours
  def appointment_reminders
    # parse time span
    match           = params[:time_span].match(/(\d+)-(day|days|hours)/)
    @number         = match[1]
    @units          = match[2]
    @timeline       = "in the next #{@number} #{@units}"

    # find all future appointments within the specified time span
    @appointments   = current_company.appointments.work.future.not_canceled.all(:conditions => ["start_at <= ?", Time.zone.now + eval("#{@number}.#{@units}")], :include => :message_topics)
    @messages       = []

    @appointments.each do |appointment|
      # check that appointment customer reminders are turned on
      next unless appointment.preferences[:reminder_customer].to_i == 1
      # check if reminder has already been sent
      message_tags = appointment.message_topics.collect(&:tag)
      next if message_tags.include?('reminder')
      # send appointment reminder
      reminders = MessageComposeAppointment.reminder(appointment)
      reminders.each do |who, message|
        case
        when !message.blank?
          # reminder message was queued/sent
          @messages.push(message)
          # reload appointment object
          appointment.reload
        end
      end
    end

    @title = "Tasks - Appointment Reminders"

    respond_to do |format|
      format.html
    end
  end
  
  # GET /tasks/users/messages/whenever
  # List all messages with users as message topics
  def user_messages
    # find users as message topics
    @topics       = MessageTopic.for_type(User).all(:include => :topic)
    @messages     = []
    @title        = "Tasks - User Messages"

    respond_to do |format|
      format.html
    end
  end

  # GET /tasks/schedules/messages/daily
  # Send (daily, monthly, ...) provider schedules as pdf emails.  Emails are sent using a delayed job.
  def schedule_messages
    # find company providers with daily schedules preference set
    @providers = current_company.authorized_providers.select{|o| o.preferences[:provider_email_daily_schedule] == '1'}

    @providers.each do |provider|
      # build url to email pdf schedule, with token to ensure request is authenticated
      @email_url  = calendar_when_format_url(:provider_type => provider.tableize, :provider_id => provider.id, :when => 'today', :format => 'email')
      @email_url  += "?token=#{AUTH_TOKEN_INSTANCE}"
      # create delayed job to generate and send pdf schedule
      @job = PdfMailerJob.new(:url => @email_url)
      Delayed::Job.enqueue(@job)
    end

    @title  = "Tasks - Schedule Messages"

    respond_to do |format|
      format.html
    end
  end


  # GET /tasks/expand_all_recurrences
  # Expand all recurrences
  # This is typically called from a delayed job (though can be called directly)
  # This will in turn queue a job to expand each recurrence
  def expand_all_recurrences
    @title = "Tasks - Expand All Recurrences"
    @number_of_recurrences = current_company.appointments.recurring.not_canceled.count
    @time_horizon = Time.zone.now.beginning_of_day + current_company.preferences[:time_horizon].to_i
    Appointment.expand_all_recurrences(current_company)

    respond_to do |format|
      format.html
    end
  end

end