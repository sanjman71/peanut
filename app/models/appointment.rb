class Appointment < ActiveRecord::Base
  belongs_to              :company
  belongs_to              :job
  belongs_to              :resource
  belongs_to              :customer
  validates_presence_of   :company_id, :job_id, :resource_id, :customer_id, :start_at, :end_at
  before_save             :init_duration
  
  named_scope :company,     lambda { |id| { :conditions => {:company_id => id} }}
  named_scope :job,         lambda { |id| { :conditions => {:job_id => id} }}
  named_scope :resource,    lambda { |id| { :conditions => {:resource_id => id} }}
  named_scope :customer,    lambda { |id| { :conditions => {:customer_id => id} }}

  # find appointments within time ranges
  named_scope :after,       lambda { |at| { :conditions => ["start_at > ?", at] }}
  named_scope :before,      lambda { |at| { :conditions => ["end_at < ?", at] }}

  # find available time ranges
  named_scope :available,   { :conditions => {:job_id => ((job = Job.available.first) ? job.id : 0)} }
  
  def after_initialize
    if self.start_at and self.job_id and self.end_at.nil?
      # initialize end_at
      self.end_at = self.start_at + self.job.duration_to_seconds
    end
  end
  
  def validate
    if self.start_at and self.end_at
      # only check if we have valid times
      if !(start_at.to_i < end_at.to_i)
        errors.add_to_base("Appointment start time must be earlier than the apointment end time")
      end
    end
  end

  # START: time virtual attributes
  def start_at_string
    self.start_at.to_s
  end
  
  def start_at_string=(s)
    self.start_at = Chronic.parse(s)
  end

  def end_at_string
    self.end_at.to_s
  end
  
  def end_at_string=(s)
    self.end_at = Chronic.parse(s)
  end
  # END: time virtual attributes
  
  # allow assignment of customer attributes when creating an appointment
  # will only create a new customer if it doesn't already exist
  def customer_attributes=(customer_attributes)
    self.customer = Customer.find_by_name(customer_attributes["name"]) || self.create_customer(customer_attributes)
  end
  
  # split an available appointment into multiple appointments with the specified job and time range
  def split(job, job_start_at, job_end_at, options={})
    # check that the current appointment is available
    raise ArgumentError if self.job.name != Job::AVAILABLE

    # validate job argument
    raise ArgumentError if job.blank? or !job.is_a?(Job)
    
    # convert argument Strings to ActiveSupport::TimeWithZones
    job_start_at = Time.zone.parse(job_start_at) if job_start_at.is_a?(String)
    job_end_at   = Time.zone.parse(job_end_at) if job_end_at.is_a?(String)
    
    # time arguments should be a ActiveSupport::TimeWithZone
    raise ArgumentError if !job_start_at.is_a?(ActiveSupport::TimeWithZone) or !job_end_at.is_a?(ActiveSupport::TimeWithZone)
        
    # check that the job_start_at and job_end_at times fall within the appointment timeslot
    raise ArgumentError unless job_start_at.between?(self.start_at, self.end_at) and job_end_at.between?(self.start_at, self.end_at)
    
    # build new appointment
    new_appt = Appointment.new(self.attributes)
    new_appt.job      = job
    new_appt.start_at = job_start_at
    new_appt.end_at   = job_end_at
    
    # build new start, end appointments
  
    unless job_start_at == self.start_at
      # the start appoint starts at the same time but ends when the new appoint starts
      start_appt = Appointment.new(self.attributes)
      start_appt.start_at = self.start_at
      start_appt.end_at   = new_appt.start_at
    end
    
    unless job_end_at == self.end_at
      # the end appointment ends at the same time, but starts when the new appointment ends
      end_appt = Appointment.new(self.attributes)
      end_appt.start_at = new_appt.end_at
      end_appt.end_at   = self.end_at
    end
    
    appointments = [start_appt, new_appt, end_appt].compact
    
    if options[:commit].to_i == 1
      
      # commit the apointment changes
      transaction do
        self.destroy
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
  
  private
  
  # initialize duration to minutes
  def init_duration
    self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
  end

end
