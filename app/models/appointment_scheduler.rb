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
    new_appt          = Appointment.new(appointment.attributes)
    new_appt.service  = service
    new_appt.start_at = service_start_at
    new_appt.end_at   = service_end_at
    new_appt.mark_as  = service.mark_as
    new_appt.duration = service.duration
    new_appt.customer = options[:customer] if options[:customer]
    
    # build new start, end appointments
    unless service_start_at == appointment.start_at
      # the start appoint starts at the same time but ends when the new appoint starts
      start_appt          = Appointment.new(appointment.attributes)
      start_appt.start_at = appointment.start_at
      start_appt.end_at   = new_appt.start_at
      start_appt.mark_as  = Appointment::FREE
      start_appt.duration -= service.duration
    end
    
    unless service_end_at == appointment.end_at
      # the end appointment ends at the same time, but starts when the new appointment ends
      end_appt            = Appointment.new(appointment.attributes)
      end_appt.start_at   = new_appt.end_at
      end_appt.end_at     = appointment.end_at
      end_appt.mark_as    = Appointment::FREE
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
  def self.create_free_appointment(company, person, start_at, end_at)
    # find first service scheduled as 'free'
    service     = company.services.free.first

    raise AppointmentInvalid, "Could not find 'free' service" if service.blank?
    
    # create a new appointment object
    customer    = Customer.nobody
    appointment = Appointment.new(:start_at => start_at, :end_at => end_at, :mark_as => service.mark_as, :service => service, :company => company,
                                  :person => person, :customer_id => customer.id)
                              
    if appointment.conflicts?
      raise TimeslotNotEmpty
    end
    
    # save appointment
    appointment.save
    
    appointment
  end
  
end