module AppointmentsHelper
  
  def build_appointment_state_search_links(url_params, state_collection, current_state, options={})
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
  
  # build possible state transitions based on current appointment state
  def build_appointment_state_transition_links(appointment)
    transitions = []
    transitions.push(['Mark as completed', complete_appointment_path(appointment)]) unless appointment.completed? || appointment.canceled?
    transitions.push(['Mark as noshow', noshow_appointment_path(appointment)]) unless appointment.noshow? || appointment.canceled?
    transitions.push(['Mark as canceled', cancel_appointment_path(appointment)]) unless appointment.canceled?
    
    transitions.each_with_index do |tuple, i|
      # use separator unless its the last element
      separator = (i == (transitions.size-1)) ? '' : '&nbsp;|&nbsp;'
      text, url = tuple
      yield text, url, separator
    end
  end

  # return hash of possible start time values
  def free_slot_possible_start_times(slot, duration_in_seconds, options={})
    # initialize hash with apointment start_at hour and minute
    hash = {:start_hour => slot.start_at.hour, :start_minute => slot.start_at.min, :minute_interval => 5}
            
    # adjust slot end_at based on duration
    begin
      end_at = slot.end_at - duration_in_seconds
    rescue
      end_at = slot.end_at
    end
    
    # update hash with end_at hour and minute
    hash.update(:end_hour => end_at.hour, :end_minute => end_at.min)

    # update hash with options args
    hash.update(options)

    hash
  end
  
  def service_duration_select_options
    collection = []

    # add minutes in 15 minute intervals
    collection = [15, 30, 45].inject(collection) do |collection, minutes|
      collection.push(["#{minutes} minutes", minutes.minutes])
      collection
    end

    # add hours
    collection = [1, 2, 3].inject(collection) do |collection, hours|
      # convert hours to mintues for select value
      hours > 1 ? collection.push(["#{hours} hours", hours.hours]) : collection.push(["#{hours} hour", hours.hours])
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
    if appointment.recur_rule.blank?
      return ""
    end
    appointment.recur_rule =~ /FREQ=([A-Z]*);BYDAY=([A-Z,]*)/
    freq = FREQ[$1] unless $1.blank?
    days = $2.split(',').map{|d| DAYS_OF_WEEK[d]} unless $2.blank?
    if freq.blank? || days.blank? || days.empty?
      ""
    else
      "Recurs #{freq} on #{days.to_sentence} starting at #{appointment.start_at.in_time_zone.to_s(:appt_time)} and running for #{Duration.to_words(appointment.duration)}"
    end
  end
  

end
