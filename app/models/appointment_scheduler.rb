class AppointmentScheduler
  
  # create a work appointment by scheduling the specified appointment within a free timeslot
  def self.create_work_appointment(appointment)
    raise AppointmentInvalid if !appointment.valid?
    
    # should be a service that is not marked as free
    raise AppointmentInvalid if appointment.service.mark_as != Appointment::WORK
    
    # should have exactly 1 conflict
    raise TimeslotNotEmpty if appointment.conflicts.size != 1
    
    # conflict should be free time
    raise TimeslotNotEmpty if appointment.conflicts.first.service.mark_as != Appointment::FREE
    
    # split the free appointment into free/work appointments
    free_appointment  = appointment.conflicts.first
    new_appointments  = self.split_free_appointment(free_appointment, appointment.service, appointment.start_at, appointment.end_at, :commit => 1, :customer => appointment.customer)
    work_appointment  = new_appointments.select { |a| a.mark_as == Appointment::WORK }.first
  end
  
  # split a free appointment into multiple appointments using the specified service and time
  def self.split_free_appointment(appointment, service, service_start_at, service_end_at, options={})
    # validate service argument
    raise ArgumentError if service.blank? or !service.is_a?(Service)
    raise ArgumentError if appointment.service.mark_as != Appointment::FREE

    # check that the current appointment is free
    raise Appointment::AppointmentNotFree if appointment.mark_as != Appointment::FREE
    
    # convert argument Strings to ActiveSupport::TimeWithZones
    service_start_at = Time.zone.parse(service_start_at) if service_start_at.is_a?(String)
    service_end_at   = Time.zone.parse(service_end_at) if service_end_at.is_a?(String)
    
    # time arguments should now be ActiveSupport::TimeWithZone objects
    raise ArgumentError if !service_start_at.is_a?(ActiveSupport::TimeWithZone) or !service_end_at.is_a?(ActiveSupport::TimeWithZone)
        
    # check that the service_start_at and service_end_at times fall within the appointment timeslot
    raise ArgumentError unless service_start_at.between?(appointment.start_at, appointment.end_at) and 
                               service_end_at.between?(appointment.start_at, appointment.end_at)
    
    # build new appointment
    new_appt          = Appointment.new
    new_appt.resource = appointment.resource
    new_appt.company  = appointment.company
    new_appt.service  = service
    new_appt.start_at = service_start_at
    new_appt.end_at   = service_end_at
    new_appt.mark_as  = service.mark_as
    new_appt.duration = service.duration
    new_appt.customer = options[:customer]  # set to nil if no customer is specified
    
    # build new start, end appointments
    unless service_start_at == appointment.start_at
      # the start appointment starts at the same time but ends when the new appointment starts
      start_appt          = Appointment.new(appointment.attributes)
      start_appt.start_at = appointment.start_at
      start_appt.end_at   = new_appt.start_at
      start_appt.duration -= service.duration
    end
    
    unless service_end_at == appointment.end_at
      # the end appointment ends at the same time, but starts when the new appointment ends
      end_appt            = Appointment.new(appointment.attributes)
      end_appt.start_at   = new_appt.end_at
      end_appt.end_at     = appointment.end_at
      end_appt.duration   -= service.duration
    end
    
    appointments = [start_appt, new_appt, end_appt].compact
    
    if options[:commit].to_i == 1
      
      # commit the apointment changes
      Appointment.transaction do
        # remove the existing appointment first
        appointment.destroy
        
        # add new appointments
        appointments.each do |appointment|
          appointment.save
          if !appointment.valid?
            raise ActiveRecord::Rollback
          end
        end
      end
      
    end
    
    appointments
  end
    
  # create a free appointment in the specified timeslot
  def self.create_free_appointment(company, resource, start_at, end_at)
    # find first service scheduled as 'free'
    service     = company.services.free.first

    raise AppointmentInvalid, "Could not find 'free' service" if service.blank?
    
    # create a new appointment object
    appointment = Appointment.new(:start_at => start_at, 
                                  :end_at => end_at, 
                                  :mark_as => service.mark_as, 
                                  :service => service, 
                                  :resource => resource,
                                  :company => company)
                              
    if appointment.conflicts?
      raise TimeslotNotEmpty
    end
    
    # save appointment
    appointment.save
    
    appointment
  end
  
  # cancel the work appointment, and reclaim the necessary free time
  def self.cancel_work_appointment(appointment)
    raise AppointmentInvalid, "Expected a work appointment" if appointment.blank? or appointment.mark_as != Appointment::WORK
    
    # find any free time that book-ends this work appointment
    company           = appointment.company
    free_time_before  = company.appointments.free.all(:conditions => {:end_at => appointment.start_at})
    free_time_after   = company.appointments.free.all(:conditions => {:start_at => appointment.end_at})
    
    raise AppointmentInvalid, "Too many free times that overlap" if free_time_before.size > 1
    raise AppointmentInvalid, "Too many free times that overlap" if free_time_after.size > 1
    
    # combine the work appointment and any free times before/after into a single free appointment
    resource          = appointment.resource
    free_start_at     = appointment.start_at
    free_start_at     = free_time_before.first.start_at unless free_time_before.blank?
    free_end_at       = appointment.end_at
    free_end_at       = free_time_after.first.end_at unless free_time_after.blank?
    
    free_appointment  = nil
    
    # commit the apointment changes
    Appointment.transaction do
      # remove the existing work appointment
      appointment.destroy
      
      # remove any existing free appointments
      free_time_before.each do |appointment|
        appointment.destroy
      end

      free_time_after.each do |appointment|
        appointment.destroy
      end
      
      # add the new free appointment
      free_appointment = create_free_appointment(company, resource, free_start_at, free_end_at)
      if !free_appointment.valid?
        raise ActiveRecord::Rollback
      end
    end
    
    free_appointment
  end
  
  # build collection of all unscheduled appointments over the specified date range
  # returns a hash mapping dates to a appointment collection
  def self.find_unscheduled_time(company, resource, daterange, appointments=nil)
    # find all appointments over the specified daterange, order by start_at
    appointments = appointments || company.appointments.resource(resource).free_work.overlap(daterange.start_at, daterange.end_at).order_start_at
    
    # group appointments by day; note that we use the appt start_at utc value to build the day
    appointments_by_day = appointments.group_by { |appt| appt.start_at.utc.to_s(:appt_schedule_day) }
    
    unscheduled_hash = daterange.inject(Hash.new) do |hash, date|
      # build formatted appointment day string
      day_string        = date.to_s(:appt_schedule_day)

      # start with appointment for the entire day, in utc format
      day_start_at_utc  = Time.parse(day_string).utc.beginning_of_day
      day_end_at_utc    = day_start_at_utc + 1.day
      day_appointment   = Appointment.new(:start_at => day_start_at_utc, :end_at => day_end_at_utc, :mark_as => Appointment::NONE)
      
      # find appointments for the day
      day_appts         = appointments_by_day[day_string] || []
      
      # initialize array value
      hash[day_string]  = Array.new
      
      if day_appts.empty?
        # entire day is unscheduled, add full day appointment in utc format
        hash[day_string].push(day_appointment)
      else
        # note: we can build time ranges like this because the appointments are sorted by start_at times
        
        # the first unscheduled time range is from the start of the day to the start of the first appointment
        first_appt = day_appts.first
        
        if first_appt.start_at.utc > day_start_at_utc
          # add unscheduled at beginning of day, in utc format
          appt_none = Appointment.new(:start_at => day_start_at_utc, :end_at => first_appt.start_at.utc, :mark_as => Appointment::NONE)
          hash[day_string].push(appt_none)
        end
        
        # the next set of unscheduled time ranges is between successive appointments, as long they are not back to back
        day_appts.each_with_index do |appt_i, i|
          appt_j = day_appts[i+1]
          next if appt_j.blank?
          next if appt_i.end_at == appt_j.start_at
          # add unscheduled in middle of day, in utc format
          appt_none = Appointment.new(:start_at => appt_i.end_at.utc, :end_at => appt_j.start_at.utc, :mark_as => Appointment::NONE)
          hash[day_string].push(appt_none)
        end
        
        # the last set of unscheduled time ranges is between the end of the last appointment and the end of the day
        last_appt = day_appts.last
        
        if last_appt.end_at.utc < day_end_at_utc
          # add unscheduled at end of day, in utc format
          appt_none = Appointment.new(:start_at => last_appt.end_at.utc, :end_at => day_end_at_utc, :mark_as => Appointment::NONE)
          hash[day_string].push(appt_none)
        end
      end
      
      hash
    end
    
    unscheduled_hash
  end
  
end