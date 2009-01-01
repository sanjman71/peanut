module AppointmentsHelper

  def build_when_links(person, when_collection, current)
    default = Appointment::WHEN_THIS_WEEK
    
    when_collection.each do |s|
      # add css 'current' class for the current link
      klass = (s == current) ? 'current' : ''
      
      if s == default
        # no when parameter for the default value
        link  = link_to(s.titleize, person_appointments_path(person, :subdomain => @subdomain), :class => klass)
      else
        # use when parameter
        link  = link_to(s.titleize, person_appointments_path(person, :subdomain => @subdomain, :when => s), :class => klass)
      end
      
      # use separator unless its the last element
      separator = (s == when_collection.last) ? '' : '&nbsp;|&nbsp;'
      
      yield link, separator
    end
  end
  
  def appointment_description(appointment)
    "#{appointment.service.name} with #{appointment.resource.name} on #{appointment.start_at.to_s(:appt_day_date_time)}"
  end

  def appointment_waitlist_description(appointment)
    any_text = appointment.time
    any_text = "any #{any_text}" if !any_text.match(/^any/)
    "#{appointment.service.name} with #{appointment.resource.name} #{any_text} #{appointment.when}"
  end
  
end
