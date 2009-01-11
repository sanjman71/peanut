class MailWorker < Workling::Base
  
  def send_invitation(options)
    invitation  = Invitation.find_by_id(options[:id].to_i)
    signup_url  = options[:url].to_s
     
    if invitation.blank?
      logger.debug("xxx mail worker: invalid invitation #{options[:id]}")
      return
    end

    # send appointment confirmation
    InvitationNotifier.deliver_invitation(invitation, signup_url)
    logger.debug("*** mail worker: sent invitation to #{invitation.recipient_email}")
  end
  
  def send_appointment_confirmation(options)
    appointment = Appointment.find_by_id(options[:id].to_i)
    
    if appointment.blank?
      logger.debug("xxx mail worker: invalid appointment #{options[:id]}")
      return
    end
    
    # send appointment confirmation
    AppointmentNotifier.deliver_appointment_confirmation(appointment)
    logger.debug("*** mail worker: sent appointment confirmation for appointment #{appointment.id}")
  end

  def send_waitlist_confirmation(options)
    appointment = Appointment.find_by_id(options[:id].to_i)
    
    if appointment.blank?
      logger.debug("xxx mail worker: invalid appointment #{options[:id]}")
      return
    end
    
    # send appointment confirmation
    AppointmentNotifier.deliver_waitlist_confirmation(appointment)
    logger.debug("*** mail worker: sent waitlist confirmation for appointment #{appointment.id}")
  end
  
end