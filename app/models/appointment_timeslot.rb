class AppointmentTimeslot
  attr_accessor :appointment, :start_at, :end_at, :duration
  
  def initialize(attributes)
    raise ArgumentError if attributes[:appointment].blank?
    
    @appointment  = attributes[:appointment]
    @start_at     = attributes[:start_at]
    @end_at       = attributes[:end_at]
    
    # calculate timeslot duration
    @duration     = (@end_at.to_i - @start_at.to_i) / 60
  end
  
  def resource
    @appointment.resource if @appointment
  end
  
end