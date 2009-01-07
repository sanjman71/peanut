class SmsWorker < Workling::Base
  include SMSFu
  
  def waitlist_confirmation(options)
    appointment = Appointment.find_by_id(options[:id].to_i)
    
    if appointment.blank?
      logger.debug("xxx mail worker: invalid appointment #{options[:id]}")
      return
    end
    
    customer  = appointment.customer
    message   = "Waitlist for #{appointment.service.name}, confirmation #{appointment.confirmation_code}"
    send_sms_to_customer(customer, message)
  end
  
  private
  
  def send_sms_to_customer(customer, message)
    if customer.blank? or message.blank?
      logger.debug("xxx sms error, customer or message blank")
      return
    end
    
    if customer.mobile_carrier.blank?
      logger.debug("xxx sms error, mobile carrier is undefined")
      return
    end
    
    logger.debug("*** sending sms - customer: #{customer.name}, carrier: #{customer.mobile_carrier.name}, message: #{message}")
    deliver_sms(customer.phone, customer.mobile_carrier.key, message)
  end
  
end