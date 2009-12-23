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
  def appointment_messages
    # find appointments with messages
    @appointments = current_company.appointments.work.all(:include => :message_topics)
    @messages     = 0
    @timeline     = ''

    @title        = "Task Appointment Messages"

    respond_to do |format|
      format.html { render(:action => 'appointment_reminders')}
    end
  end

  # GET /tasks/appointments/reminders/2-days
  # GET /tasks/appointments/reminders/7-hours
  def appointment_reminders
    # parse time span
    match           = params[:time_span].match(/(\d+)-(days|hours)/)
    @number         = match[1]
    @units          = match[2]
    @timeline       = "in the next #{@number} #{@units}"

    # find appointments in the upcoming time span
    @appointments   = current_company.appointments.work.future.not_canceled.all(:conditions => ["start_at <= ?", Time.zone.now + eval("#{@number}.#{@units}")], :include => :message_topics)
    @messages       = 0

    @appointments.each do |appointment|
      # check that appointment reminders are turned on
      next unless appointment.preferences[:reminder].to_i == 1
      # check if reminders have already been sent
      message_tags = appointment.message_topics.collect(&:tag)
      next if message_tags.include?('reminder')
      # send appointment reminder
      message = MessageComposeAppointment.reminder(appointment)
      case
      when !message.blank?
        # reminder message was sent
        @messages += 1
        # reload appointment object
        appointment.reload
      end
    end

    @title = "Task Appointment Reminder"

    respond_to do |format|
      format.html
    end
  end
  
  # GET /tasks/users/messages/whenever
  def user_messages
    # find users as message topics
    @topics       = MessageTopic.for_type(User).all(:include => :topic)
    @messages     = 0
    @title        = "Task User Messages"

    respond_to do |format|
      format.html
    end
  end
end