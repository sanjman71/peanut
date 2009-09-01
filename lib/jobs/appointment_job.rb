class AppointmentJob < Struct.new(:params)
  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/appointments.log")
    end
  end

  def perform
    logger.info "#{Time.now}: [ok] appointment job: #{params.inspect}"

    begin
      appointment = Appointment.find(params[:id])
    rescue
      logger.error "#{Time.now}: [error] invalid appointment #{params[:id]}"
      return
    end
    
    begin
      case params[:method]
      when 'send_confirmation'
        case 
        when appointment.work?
          send_confirmation(appointment)
        else
          logger.error "#{Time.now}: [error] ignoring, can not send confirmation for a non-work appointment"
        end
      when 'send_free_time_scheduled'
        send_free_time_scheduled(appointment)
      else
        logger.error "#{Time.now}: [error] ignoring method #{params[:method]}"
      end
    rescue Exception => e
      logger.info "#{Time.now}: [error] #{e.message}, #{e.backtrace}"
    end
  end

  def send_confirmation(appointment)
    company   = appointment.company
    provider  = appointment.provider
    customer  = appointment.customer
    
    if customer and customer.email_addresses_count > 0
      # send confirmation to appointment customer
      email     = customer.primary_email_address
      protocol  = 'email'
      subject   = "[#{company.name}] appointment confirmation"
      body      = "Your appointment with #{provider.name} for ... has been confirmed."
      send_message_using_message_pub(subject, body, protocol, email.address)
    end
  end

  # used for testing
  def send_free_time_scheduled(appointment)
    protocol  = 'email'
    address   = 'sanjay@jarna.com'
    subject   = "Free Time Scheduled for #{appointment.provider.name}" 
    body      = ''

    send_message_using_message_pub(subject, body, protocol, address)
  end
  
  def send_message_using_message_pub(subject, body, protocol, address)
    logger.debug("*** #{Time.now}: *** sending message pub #{protocol} to: #{address}, subject: #{subject}, body: #{body}")

    # create notification
    notification = MessagePub::Notification.new(:body => body,
                                                :subject => subject,
                                                :escalation => 0,
                                                :recipients => {:recipient => [{:position => 1, :channel => protocol, :address => address}]})
    notification.save
  end
end