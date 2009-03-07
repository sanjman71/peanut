class AppointmentRequest < Appointment

  def find_free_appointments(options={})
    # find free appointments with duration >= appointment request's service duration
    duration    = self.duration || self.service.duration
    # use time range if it was specified, otherwise default to 'anytime'
    time_range  = Appointment.time_range(self.time(:default => 'anytime'))
    
    if schedulable.anyone?
      # find free appointments for any schedulable, order by start times
      appts = company.appointments.overlap(start_at, end_at).time_overlap(time_range).duration_gt(duration).free.general_location(location.id).order_start_at
    else
      # find free appointments for a specific schedulable, order by start times
      appts = company.appointments.schedulable(schedulable).overlap(start_at, end_at).time_overlap(time_range).duration_gt(duration).free.general_location(location.id).order_start_at
    end
    
    # filter appointments by the schedulables who can provide the service
    appts.select { |appt| self.service.provided_by?(appt.schedulable) }
  end
  
  # find free time slots based on appointment request [start_at, end_at]
  # valid options:
  #  :limit => limit the number of free time slots returned
  #  :appointments => use the appointments collection instead of building it
  def find_free_timeslots(options={})
    # parse options
    limit       = options[:limit].to_i if options[:limit]
    
    # find free appointments with duration >= service's duration
    collection  = options[:appointments] || self.find_free_appointments
    collection  = Array(collection)
    
    # iterate over free appointments
    duration    = self.duration || self.service.duration
    timeslots   = collection.inject([]) do |array, appointment|
      # narrow appointments by request start, end times
      appointment.narrow_by_time_range!(self.start_at, self.end_at)
      
      # narrow appointment by request time of day, default to 'anytime'
      appointment.narrow_by_time_of_day!(self.time(:default => 'anytime'))
      
      # build appointment timeslots
      options = Hash.new
      options[limit] = limit - array.size if limit
      array   += appointment.timeslots(duration, options)
    end
    
    timeslots
  end
  
end
