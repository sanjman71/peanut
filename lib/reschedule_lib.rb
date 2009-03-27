module RescheduleLib
  protected

  def set_reschedule_id(appointment)
    session[:reschedule_id] = appointment.id unless appointment.blank?
  end

  def get_reschedule_id
    @reschedule_id ||= session[:reschedule_id]
  end

  def get_reschedule_appointment
    @reschedule_appointment = Appointment.find_by_id(get_reschedule_id)
  end
  
  def has_reschedule_id?
    !(@reschedule_id = session[:reschedule_id]).blank?
  end
  
  def reset_reschedule_id
    session[:reschedule_id] = nil
  end

  # reset the reschedule id unless params has the 'reschedule' flag set
  def reset_reschedule_id_from_params
    session[:reschedule_id] = nil unless params['type'] == 'reschedule'
  end
  
end
