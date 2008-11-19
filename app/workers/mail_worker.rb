class MailWorker < Workling::Base
  
  def test(options)
    logger.debug("*** workling test method")
  end
  
  def appointment_confirmation(options)
    appointment = Appointment.find_by_id(options[:id].to_i)
    
    if appointment.blank?
      logger.debug("xxx mail worker: invalid appointment #{options[:id]}")
      return
    end
    
    # send appointment confirmation
    AppointmentNotifier.deliver_confirmation(appointment)
    logger.debug("*** mail worker: sent appointment confirmation for appointment #{appointment.id}")
  end
  
end