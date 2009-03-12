module AppointmentsHelper
  
  # return hash of possible start time values
  def free_appointment_possible_start_times(appointment, duration_in_minutes, options={})
    # initialize hash with apointment start_at hour and minute
    hash = {:start_hour => appointment.start_at.hour, :start_minute => appointment.start_at.min}
            
    # adjust appointment end_at based on duration
    begin
      end_at = appointment.end_at - eval("#{duration_in_minutes}.minutes")
    rescue
      end_at = appointment.end_at
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
  
  # return duration as a string description
  # options:
  #  - exact => if true, use exact wording, otherwise use 'typically' in phrase; defaults to true
  def service_duration_in_words(duration_in_minutes, options={})
    return '' if duration_in_minutes.blank? or duration_in_minutes == 0

    use_exact_phrase    = options.has_key?(:exact) ? options[:exact] : true
    
    # force duration to integer
    duration_in_minutes = duration_in_minutes.to_i
    
    if duration_in_minutes >= 60
      # use hours
      hours, mins = [duration_in_minutes / 60, duration_in_minutes % 60]
      phrase = mins > 0 ? "#{pluralize(hours, 'hour')}, #{pluralize(mins, 'minute')}" : "#{pluralize(hours, 'hour')}"
    else
      # use minutes
      phrase = "#{duration_in_minutes} minutes"
    end
    
    # format phrase based on exact option
    phrase = "Typically #{phrase}" if !use_exact_phrase
    
    phrase
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
  
end
