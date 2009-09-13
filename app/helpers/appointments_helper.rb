module AppointmentsHelper
  
  def build_appointment_state_when_links(url_params, state_collection, current_state, options={})
    default = options[:default]
    
    state_collection.each do |state|
      # add css 'current' class for the current link
      klass = (state == current_state) ? 'current' : ''
      
      if state == default
        # no state parameter for the default value
        link  = link_to(state.titleize, url_for(url_params.update(:state => nil, :subdomain => current_subdomain)), :class => klass)
      else
        # use state parameter
        link  = link_to(state.titleize, url_for(url_params.update(:state => state.to_url_param, :subdomain => current_subdomain)), :class => klass)
      end
      
      # use separator unless its the last element
      separator = (state == state_collection.last) ? '' : '&nbsp;|&nbsp;'
      
      yield link, separator
    end
  end
  
  # return hash of possible start time values
  def free_slot_possible_start_times(slot, duration_in_minutes, options={})
    # initialize hash with apointment start_at hour and minute
    hash = {:start_hour => slot.start_at.hour, :start_minute => slot.start_at.min}
            
    # adjust slot end_at based on duration
    begin
      end_at = slot.end_at - eval("#{duration_in_minutes}.minutes")
    rescue
      end_at = slot.end_at
    end
    
    # update hash with end_at hour and minute
    hash.update(:end_hour => end_at.hour, :end_minute => end_at.min)
    
    # set minute interval based on duration
    case duration_in_minutes
    when (0..60)
      minute_interval = 30
    else
      # default value
      minute_interval = 30
    end
    
    hash.update(:minute_interval => minute_interval).update(options)
  end
  
  def service_duration_select_options
    collection = []
    
    # add minutes in 15 minute intervals
    collection = [15, 30, 45].inject(collection) do |collection, minutes|
      collection.push(["#{minutes} minutes", minutes])
      collection
    end

    # add hours
    collection = [1, 2, 3].inject(collection) do |collection, hours|
      # convert hours to mintues for select value
      hours > 1 ? collection.push(["#{hours} hours", hours*60]) : collection.push(["#{hours} hour", hours*60])
      collection
    end
    
    collection
  end
  
  def appointment_starts_at_distance_in_words(appointment, time=Time.now)
    if time < @appointment.start_at
      # appointment starts in the future
      "#{distance_of_time_in_words_to_now(@appointment.start_at)} from now"
    elsif time > @appointment.end_at
      # appointment has ended
      "#{distance_of_time_in_words_to_now(@appointment.end_at)} ago"
    else
      "Its happening now"
    end
  end

  FREQ = {
    "WEEKLY" => "Weekly"
  }

  DAYS_OF_WEEK = 
    {
      "SU" => "Sunday",
      "MO" => "Monday",
      "TU" => "Tuesday",
      "WE" => "Wednesday",
      "TH" => "Thursday",
      "FR" => "Friday",
      "SA" => "Saturday"
    }

  def appointment_recur_rule_in_words(appointment)
    appointment.recur_rule =~ /FREQ=([A-Z]*);BYDAY=([A-Z,]*)/
    freq = FREQ[$1]
    days = $2.split(',').map{|d| DAYS_OF_WEEK[d]}
    "Recurs #{freq} on #{days.to_sentence} starting at #{appointment.start_at.to_s[:appt_time]} and running for #{appointment_duration_in_words(appointment)}"
  end
  
  def appointment_duration_in_words(appointment)
    duration = appointment.duration
    if (duration == 0)
      "0 minutes"
    else
      days = (duration / (24 * 60)).to_i
      duration -= (days * 24 * 60)
      hours = duration / (24 * 60)
      duration -= (hours * 60)
      minutes = duration / 60
      duration -= minutes
      res = []
      res << "#{days} days" unless (days == 0)
      res << "#{hours} hours" unless (hours == 0)
      res << "#{minutes} minutes" unless (minutes == 0)
      res.to_sentence
    end
  end
  
end
