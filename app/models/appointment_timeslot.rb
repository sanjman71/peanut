class AppointmentTimeslot
  attr_accessor :appointment, :start_at, :end_at, :duration
  
  def initialize(appointment)
    raise ArgumentException if appointment.blank?
    
    @appointment  = appointment
    @start_at     = @appointment.start_at
    @duration     = @appointment.duration
    @end_at       = @start_at + @duration.minutes
  end
  
  def person
    @appointment.person if @appointment
  end
  
end