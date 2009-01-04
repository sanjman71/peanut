class WaitlistWorker < Workling::Base
  
  def check_appointment_waitlist(options)
    appointment = Appointment.find_by_id(options[:id].to_i)
    
    if appointment.blank?
      logger.debug("xxx waitlist worker: invalid appointment #{options[:id]}")
      return
    end
    
    logger.debug("*** checking waitlist for #{appointment.mark_as} appointment #{appointment.id}")
    
    waitlist_appts = appointment.waitlist
    
    logger.debug("*** found #{waitlist_appts.size} waitlist appointments")
    
    waitlist_appts.each do |waitlist_appt|
      # send waitlist opening email
      AppointmentNotifier.deliver_waitlist_opening(waitlist_appt)
      logger.debug("*** mail worker: sent waitlist opening for waitlist appointment #{waitlist_appt.id}")
    end
  end
  
end