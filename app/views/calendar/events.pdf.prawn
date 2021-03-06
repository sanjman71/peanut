pdf.text("Schedule for #{@provider.name} [#{@daterange.name(:with_dates => true)}]", :size => 15, :style => :bold)

pdf.move_down(10)

# pdf.fill_color("111111")
# pdf.text("#{@daterange.name(:with_dates => true)}", :size => 15)

pdf.fill_color("000000")
pdf.move_down(10)

pdf.stroke_color "aaaaaa"

if @capacity_and_work_by_day.blank?
  pdf.text("No Appointments Scheduled")
else
  @capacity_and_work_by_day.each do |day, stuff|
    # date
    pdf.fill_color("008800")
    pdf.text("#{day.to_s(:appt_day)}")
    pdf.fill_color("000000")

    rows = []

    stuff.each do |object|
      if object.is_a?(Appointment) && object.free?
        appointment = object
        next if appointment.canceled?
        rows.push([
                    appointment.start_at.to_s(:appt_time),
                    appointment.end_at.to_s(:appt_time),
                    Duration.to_words(appointment.duration),
                    "Scheduled Availability",
                    "#{pluralize(appointment.capacity, 'slot')} made available"
                  ])
      elsif object.is_a?(Appointment) && object.work?
        appointment = object
        # skip canceled appointments
        next if appointment.canceled?
        rows.push([
                    appointment.start_at.to_s(:appt_time),
                    appointment.end_at.to_s(:appt_time),
                    Duration.to_words(appointment.duration),
                    appointment.service.name,
                    appointment.customer ? appointment.customer.name : ""
                  ])
      elsif object.is_a?(CapacitySlot)
        capacity_slot = object
        rows.push([
                  capacity_slot.start_at.to_s(:appt_time),
                  capacity_slot.end_at.to_s(:appt_time),
                  Duration.to_words(capacity_slot.duration),
                  (capacity_slot.capacity >= 1) ? "Free - #{pluralize(capacity_slot.capacity, 'slot')} available" : "Overbooked by #{pluralize(capacity_slot.capacity.abs, 'slot')}",
                  ""
                  ])
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
    
    if !rows.empty?
      pdf.table rows, 
        :border_style => :grid,  
        :row_colors => ["FFFFFF", "DDDDDD"],  
        :headers => ["Start Time", "End Time", "Duration", "Service", "Customer"],  
        :align => { 0 => :right, 1 => :right }
      
      pdf.move_down(15)
    end
  end
end