class CacheKey
  
  # Create cache key for a collection of appointments over a specified daterange
  def self.schedule(daterange, appointments, time_of_day)
    # use daterange start, end dates
    date_key  = "#{daterange.start_at.to_s(:appt_schedule)}:#{daterange.end_at.to_s(:appt_schedule)}"
    date_key  += ":#{time_of_day}" if !time_of_day.blank?
    
    # add appointment info
    # appt_keys = appointments.collect { |a| "#{a.id}:#{a.updated_at.to_s(:appt_schedule)}" }
    appt_keys = appointments.collect { |a| a.cache_key }
    
    # build cache key
    cache_key = date_key + ":" + appt_keys.join(":")
  end
  
end