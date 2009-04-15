pdf.text("Schedule for #{@provider.name}", :size => 20, :style => :bold)

pdf.move_down(10)

pdf.fill_color("5500BB")
pdf.text("#{@daterange.name(:with_dates => true)}", :size => 15)

pdf.fill_color("000000")
pdf.move_down(10)

pdf.stroke_color "aaaaaa"

if @appointments_by_day.blank?
  pdf.text("No Appoinments Scheduled")
else
  @appointments_by_day.each do |day, appointments|
    # date
    pdf.fill_color("008800")
    pdf.text("#{day.to_s(:appt_day)}")
    pdf.fill_color("000000")
    
    # show table of appointments for the date
    rows = appointments.map do |appointment|
      [
        appointment.start_at.to_s(:appt_time),
        appointment.end_at.to_s(:appt_time),
        Duration.to_words(appointment.duration),
        appointment.service.name,
        appointment.customer ? appointment.customer.name : ""
      ]
    end
    
    pdf.table rows, 
      :border_style => :grid,  
      :row_colors => ["FFFFFF", "DDDDDD"],  
      :headers => ["Start Time", "End Time", "Duration", "Service", "Customer"],  
      :align => { 0 => :right, 1 => :right }
      
    pdf.move_down(15)
  end
end