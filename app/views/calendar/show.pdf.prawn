pdf.text("Schedule for #{@provider.name}", :size => 20, :style => :bold)

pdf.move_down(10)

pdf.fill_color("5500BB")
pdf.text("#{@daterange.name(:with_dates => true)}", :size => 15)

pdf.fill_color("000000")
pdf.move_down(10)

pdf.stroke_color "aaaaaa"

if @stuff_by_day.blank?
  pdf.text("No Appoinments Scheduled")
else
  @stuff_by_day.each do |day, stuff|
    # date
    pdf.fill_color("008800")
    pdf.text("#{day.to_s(:appt_day)}")
    pdf.fill_color("000000")

    rows = []

    stuff.each do |object|
      if object.is_a?(Appointment) && object.free?
        # find capacity and work objects for this free appointment
        @capacity_and_work_by_free_appt[object.id].each do |capacity_or_appointment|
          if capacity_or_appointment.is_a?(Appointment) && capacity_or_appointment.work?
            appointment = capacity_or_appointment
            # skip canceled appointments
            next if appointment.canceled?
            rows.push([
                        appointment.start_at.to_s(:appt_time),
                        appointment.end_at.to_s(:appt_time),
                        Duration.to_words(appointment.duration),
                        appointment.service.name,
                        appointment.customer ? appointment.customer.name : ""
                      ])
          elsif capacity_or_appointment.is_a?(CapacitySlot)
            capacity_slot = capacity_or_appointment
            rows.push([
                      capacity_slot.start_at.to_s(:appt_time),
                      capacity_slot.end_at.to_s(:appt_time),
                      Duration.to_words(capacity_slot.duration),
                      capacity_slot.free_appointment.service.name,
                      capacity_slot.free_appointment.customer ? capacity_slot.free_appointment.customer.name : ""
                      ])
          end
        end
      end
    end
    
    # show table of appointments for the date
    # rows = appointments.map do |appointment|
    #   [
    #     appointment.start_at.to_s(:appt_time),
    #     appointment.end_at.to_s(:appt_time),
    #     Duration.to_words(appointment.duration),
    #     appointment.service.name,
    #     appointment.customer ? appointment.customer.name : ""
    #   ]
    # end
    
    pdf.table rows, 
      :border_style => :grid,  
      :row_colors => ["FFFFFF", "DDDDDD"],  
      :headers => ["Start Time", "End Time", "Duration", "Service", "Customer"],  
      :align => { 0 => :right, 1 => :right }
      
    pdf.move_down(15)
  end
end