class Appointment < ActiveRecord::Base
  belongs_to :company
  belongs_to :job
  belongs_to :resource
  belongs_to :customer
  validates_presence_of :company_id, :job_id, :resource_id, :customer_id, :start_at, :end_at
  before_save :init_duration
  
  named_scope :company,     lambda { |id| { :conditions => {:company_id => id} }}
  named_scope :job,         lambda { |id| { :conditions => {:job_id => id} }}
  named_scope :resource,    lambda { |id| { :conditions => {:resource_id => id} }}
  named_scope :customer,    lambda { |id| { :conditions => {:customer_id => id} }}
  
  def validate
    unless self.start_at.nil? or self.end_at.nil?
      # only check if we have valid times
      if !(start_at.to_i < end_at.to_i)
        errors.add_to_base("appointment start time must be earlier than the apointment end time")
      end
    end
  end

  # split an available timeslot into available and busy timeslots
  def split(start_at, end_at)
    # check that the current timeslot is available
    raise ArgumentError if self.job.name != Job.available
    
    # time arguments should be strings
    raise ArgumentError if !start_at.is_a?(String) or !end_at.is_a?(String)
    
    # convert strings to TimeZone objects
    tz_start_at = Time.zone.parse(start_at)
    tz_end_at   = Time.zone.parse(end_at)
    
    # check that the start_at and end_at times fall within the appointment timeslot
    raise ArgumentError unless tz_start_at.between?(self.start_at, self.end_at) and tz_end_at.between?(self.start_at, self.end_at)
    
    # build new appointment
    new_appt = Appointment.new(self.attributes)
    new_appt.start_at = tz_start_at
    new_appt.end_at   = tz_end_at
    
    # build new start, end appointments
  
    unless tz_start_at == self.start_at
      # the start appoint starts at the same time but ends when the new appoint starts
      start_appt = Appointment.new(self.attributes)
      start_appt.start_at = self.start_at
      start_appt.end_at   = new_appt.start_at
    end
    
    unless tz_end_at == self.end_at
      # the end appointment ends at the same time, but starts when the new appointment ends
      end_appt = Appointment.new(self.attributes)
      end_appt.start_at = new_appt.end_at
      end_appt.end_at   = self.end_at
    end
    
    [start_appt, new_appt, end_appt].compact
  end
  
  private
  
  def init_duration
    self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
  end

end
