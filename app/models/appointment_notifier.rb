class AppointmentNotifier < ActionMailer::Base

  def confirmation(appointment)
    setup_email(appointment, appointment.customer)
    @subject = "Peanut Appointment Confirmation - #{appointment.confirmation_code}"
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