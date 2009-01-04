class AppointmentNotifier < ActionMailer::Base

  def appointment_confirmation(appointment)
    setup_email(appointment, appointment.customer)
    @subject = "#{appointment.company.name} Appointment Confirmation - #{appointment.confirmation_code}"
  end

  def waitlist_confirmation(appointment)
    setup_email(appointment, appointment.customer)
    @subject = "#{appointment.company.name} Waitlist Confirmation - #{appointment.confirmation_code}"
  end
  
  def waitlist_opening(appointment)
    setup_email(appointment, appointment.customer)
    @subject = "#{appointment.company.name} Waitlist Opening - #{appointment.confirmation_code}"
  end
  
  protected
  
  def setup_email(appointment, customer)
    @recipients           = "#{customer.email}"
    @from                 = "peanut@jarna.com"
    
    # add environment info if its not production
    # if RAILS_ENV != "production"
    #   @subject += " (#{RAILS_ENV}) "
    # end
    
    @sent_on              = Time.now
    @body[:customer]      = customer
    @body[:appointment]   = appointment
  end
  
end