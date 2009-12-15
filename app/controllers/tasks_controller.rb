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
  def appointments_messages
    # find appointments with messages
    @appointments = current_company.appointments.work.all(:include => :message_topics)
    @reminders    = 0

    @title        = "Task Appointment Messages"

    respond_to do |format|
      format.html { render(:action => 'appointments_reminders')}
    end
  end

  # GET /tasks/appointments/reminders/2-days
  # GET /tasks/appointments/reminders/7-hours
  def appointments_reminders
    # parse time span
    match           = params[:time_span].match(/(\d+)-(days|hours)/)
    @number         = match[1]
    @units          = match[2]
    
    # find appointments in the upcoming time span
    @appointments   = current_company.appointments.work.future.all(:conditions => ["start_at <= ?", Time.zone.now + eval("#{@number}.#{@units}")], :include => :message_topics)
    @reminders      = 0

    @appointments.each do |appointment|
      # check appointment messages already sent
      message_tags = appointment.message_topics.collect(&:tag)
      next if message_tags.include?('reminder')
      # send appointment reminder
      success = MessageComposeAppointment.reminder(appointment)
      case success
      when 0
        # reminder was sent
        @reminders += 1
        # reload appointment object
        appointment.reload
      end
    end

    @title = "Task Appointment Reminder"

    respond_to do |format|
      format.html
    end
  end
  
end