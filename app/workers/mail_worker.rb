class MailWorker < Workling::Base
  
  def send_invitation(options)
    invitation  = Invitation.find_by_id(options[:id].to_i)
    signup_url  = options[:url].to_s
     
    if invitation.blank?
      logger.debug("xxx mail worker: invalid invitation #{options[:id]}")
      return
    end

    InvitationNotifier.deliver_invitation(invitation, signup_url)
    logger.debug("*** mail worker: sent invitation to #{invitation.recipient_email}")
  end
  
  def send_appointment_confirmation(options)
    appointment = Appointment.find_by_id(options[:id].to_i)
    
    if appointment.blank?
      logger.debug("xxx mail worker: invalid appointment #{options[:id]}")
      return
    end
    
    case appointment.mark_as
    when Appointment::WORK
      AppointmentNotifier.deliver_work_confirmation(appointment)
      logger.debug("*** mail worker: sent work appointment confirmation for appointment #{appointment.id}")
    when Appointment::WAIT
      AppointmentNotifier.deliver_waitlist_confirmation(appointment)
      logger.debug("*** mail worker: sent waitlist appointment confirmation for appointment #{appointment.id}")
    end    
  end

  def send_account_created(options)
    company   = Company.find_by_id(options[:company_id].to_i)
    user      = User.find_by_id(options[:user_id].to_i)
    creator   = User.find_by_id(options[:creator_id].to_i)
    password  = options[:password]
    login_url = options[:login_url]
    
    UserMailer.deliver_account_created(company, user, creator, password, login_url)
    logger.debug("*** mail worker: sent account created email to #{user.email}")
  end

  def send_account_reset(options)
    company   = Company.find_by_id(options[:company_id].to_i)
    user      = User.find_by_id(options[:user_id].to_i)
    password  = options[:password]
    login_url = options[:login_url]
    
    UserMailer.deliver_account_reset(company, user, password, login_url)
    logger.debug("*** mail worker: sent account reset email to #{user.email}")
  end
end