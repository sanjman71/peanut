class AppointmentRequest < Appointment

  def find_free_appointments(options={})
    # find free appointments with duration >= this request's service duration
    duration    = self.service.duration
    
    if person_id.blank?
      # find free appointments for any person, order by start times
      collection = self.company.appointments.span(start_at, end_at).duration_gt(duration).free.all(:order => 'start_at')
    else
      # find free appointments for a specific person, order by start times
      collection = self.company.appointments.person(person_id).span(start_at, end_at).duration_gt(duration).free.all(:order => 'start_at')
    end
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
    duration    = self.service.duration
    timeslots   = collection.inject([]) do |array, appointment|
      # create appointment timeslot
      timeslot = AppointmentTimeslot.new(appointment)
      
      # resize timeslot if free appointment is larger than requested appointment
      timeslot.start_at = self.start_at if appointment.start_at < self.start_at
      timeslot.end_at   = self.end_at if appointment.end_at > self.end_at
      timeslot.duration = (timeslot.end_at.to_i - timeslot.start_at.to_i) / 60

      # break timeslot into chunks based on service duration
      chunks = timeslot.duration / duration
      
      # apply limit based on current array size
      chunks = (limit - array.size) if limit
      
      0.upto(chunks-1) do |i|
        # clone timeslot, then increment start_at based on chunk index
        timeslot_i = timeslot.clone
        timeslot_i.start_at = timeslot.start_at + (i * duration).minutes
        timeslot_i.end_at   = timeslot_i.start_at + duration.minutes
        timeslot_i.duration = duration
        array << timeslot_i
      end
      
      array
    end
    
    timeslots
  end
  
end
