class AppointmentRequest < Appointment

  def find_free_appointments(options={})
    # find free appointments with duration >= this request's job duration
    duration    = self.job.duration
    if resource_id.blank?
      # find free appointments for any resource
      collection = Appointment.company(company_id).span(start_at, end_at).duration_gt(duration).free
    else
      # find free appointments for a specific resource
      collection = Appointment.company(company_id).resource(resource_id).span(start_at, end_at).duration_gt(duration).free
    end
  end
  
  # find free time slots based on appointment request [start_at, end_at]
  # valid options:
  #  :limit => limit the number of free time slots returned
  def find_free_timeslots(options={})
    # parse options
    limit       = options[:limit].to_i if options[:limit]
    
    # find free appointments with duration >= job's duration
    collection  = self.find_free_appointments
    
    # iterate over free appointments
    duration    = self.job.duration
    timeslots   = collection.inject([]) do |array, appointment|
      # create timeslot
      timeslot = Timeslot.new(appointment.start_at, appointment.duration)
      timeslot.appointment_id = appointment.id
      
      # resize timeslot if free appointment is larger than requested appointment
      timeslot.start_at = self.start_at if appointment.start_at < self.start_at
      timeslot.end_at   = self.end_at if appointment.end_at > self.end_at
      timeslot.duration = (timeslot.end_at.to_i - timeslot.start_at.to_i) / 60

      # break timeslot into chunks based on job duration
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
