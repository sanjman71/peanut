module AppointmentRescheduleHelper
  protected

  def set_reschedule_appointment(appointment)
    session[:reschedule_id] = "#{appointment.id}:#{Time.zone.now.to_s(:appt_schedule)}" unless appointment.blank?
  end

  def get_reschedule_appointment
    @reschedule_appointment ||= reschedule_from_session
    @reschedule_appointment = false if @reschedule_appointment.nil?
    @reschedule_appointment
  end

  def reset_reschedule_appointment
    session[:reschedule_id] = nil
  end

  def get_reschedule_start_message(appointment)
    return '' if appointment.blank?
    if appointment.customer == current_user
      "Rescheduling your appointment"
    else
      "Rescheduling #{appointment.customer.name}'s appointment" 
    end
  end

  private

  def reschedule_from_session
    return nil if session[:reschedule_id].blank?
    id, timestamp = session[:reschedule_id].split(':') # e.g. '1', '20100101T120000'
    # check timestamp
    return nil if (Time.zone.parse(timestamp) + reschedule_expiration) < Time.zone.now
    # the timestamp is valid, get the apointment
    Appointment.find_by_id(id)
  end

  def reschedule_expiration
    5.minutes
  end

end
