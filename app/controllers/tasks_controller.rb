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
    @messages     = 0
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
    @messages       = 0

    @appointments.each do |appointment|
      # check that appointment customer reminders are turned on
      next unless appointment.preferences[:reminder_customer].to_i == 1
      # check if reminder has already been sent
      message_tags = appointment.message_topics.collect(&:tag)
      next if message_tags.include?('reminder')
      # send appointment reminder
      message = MessageComposeAppointment.reminder(appointment)
      case
      when !message.blank?
        # reminder message was queued/sent
        @messages += 1
        # reload appointment object
        appointment.reload
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
    @messages     = 0
    @title        = "Tasks - User Messages"

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
    @number_of_recurrences = current_company.appointments.recurring.count
    @time_horizon = Time.zone.now.beginning_of_day + current_company.preferences[:time_horizon].to_i
    Appointment.expand_all_recurrences(current_company)
    respond_to do |format|
      format.html
    end
  end

  # GET /tasks/users/1/send_pdf_schedule/today
  # Send pdf schedule to the specified user
  def send_pdf_schedule
    @user     = User.find(params[:user_id])
    @when     = params[:today].to_s
    @subject  = (@when == 'today') ? "Today's PDF Schedule" : "Your PDF Schedule"

    # build url to generate pdf schedule, with token to ensure request is authenticated
    @url      = calendar_when_format_url(:provider_type => @user.class.to_s.tableize, :provider_id => @user.id, :when => @when, :format => 'pdf')
    @url      += "?token=#{AUTH_TOKEN_INSTANCE}"

    @email    = @user.primary_email_address

    if @email.blank?
      flash[:error] = "User #{@user.name} does not have an email address"
    else
      # create delayed job to generate and send pdf schedule
      @job = PdfMailerJob.new(:url => @url, :address => 'sanjay@jarna.com', :subject => @subject)
      Delayed::Job.enqueue(@job)
      flash[:notice] = "Sent #{@when} PDF Schedule to #{@user.name}"
    end

    redirect_to(tasks_path) and return
  end

end