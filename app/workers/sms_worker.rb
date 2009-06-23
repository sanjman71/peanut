class SmsWorker < Workling::Base
  include SMSFu
  
  def send_appointment_confirmation(options)
    appointment = Appointment.find_by_id(options[:id].to_i)
    
    if appointment.blank?
      logger.debug("xxx mail worker: invalid appointment #{options[:id]}")
      return
    end
    
    case appointment.mark_as
    when Appointment::WORK
      customer  = appointment.customer
      message   = "#{appointment.service.name} confirmation"

      # Create an log_entry with the SMS message saying we sent the SMS
      appointment.company.log_entries.create(:etype => LogEntry::INFORMATIONAL, :loggable => appointment,
                                        :message_id => LogEntriesHelper::LOG_ENTRY_MESSAGE_IDS[:sent_appointment_confirmation_sms],
                                        :message_body => message,
                                        :customer => appointment.customer)
      
      send_sms_to_user(customer, message)
    when Appointment::WAIT
      customer  = appointment.customer
      message   = "Your are waitlisted for a #{appointment.service.name}"

      # Create an log_entry with the SMS message saying we sent the SMS
      appointment.company.log_entries.create(:etype => LogEntry::INFORMATIONAL, :loggable => appointment,
                                        :message_id => LogEntriesHelper::LOG_ENTRY_MESSAGE_IDS[:sent_waitlist_confirmation_sms],
                                        :message_body => message,
                                        :customer => appointment.customer)

      send_sms_to_user(customer, message)
    end
  end
  
  def send_message(options)
    company   = Company.find_by_id(options[:company_id].to_i)
    user      = User.find_by_id(options[:user_id].to_i)
    message   = options[:message]
    send_sms_to_user(user, "#{company.name}: #{message}")
  end
  
  private
  
  def send_sms_to_user(user, message)
    if user.blank? or message.blank?
      logger.debug("xxx sms error, user or message blank")
      return
    end
    
    if user.mobile_carrier.blank?
      logger.debug("xxx sms error, mobile carrier is undefined")
      return
    end
    
    logger.debug("*** sending sms - user: #{user.name}, carrier: #{user.mobile_carrier.name}, message: #{message}")
    deliver_sms(user.phone, user.mobile_carrier.key, message)
  end
  
end