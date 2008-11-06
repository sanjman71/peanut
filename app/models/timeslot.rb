class Timeslot
  attr_accessor :start_at, :end_at, :duration, :appointment_id
  
  def initialize(start_at, duration)
    @start_at = start_at
    @duration = duration
    @end_at   = @start_at + @duration.minutes
  end
  
  # belongs_to appointment
  def appointment
    Appointment.find_by_id(@appointment_id)
  end
  
end