# define exception classes
class AppointmentNotFree < Exception; end
class TimeslotNotEmpty < Exception; end
class AppointmentInvalid < Exception; end

class Appointment < ActiveRecord::Base
  belongs_to              :company
  belongs_to              :job
  belongs_to              :resource
  belongs_to              :customer
  validates_presence_of   :company_id, :job_id, :resource_id, :customer_id, :start_at, :end_at
  validates_inclusion_of  :mark_as, :in => %w(free busy work)
  
  named_scope :company,     lambda { |id| { :conditions => {:company_id => id} }}
  named_scope :job,         lambda { |id| { :conditions => {:job_id => id} }}
  named_scope :resource,    lambda { |id| { :conditions => {:resource_id => id} }}
  named_scope :customer,    lambda { |id| { :conditions => {:customer_id => id} }}
  named_scope :duration_gt, lambda { |t|  { :conditions => ["duration >= ?", t] }}
  
  # find appointments spanning a time range
  named_scope :span,        lambda { |start_at, end_at| { :conditions => ["(start_at < ? AND end_at > ?) OR (start_at < ? AND end_at > ?) OR 
                                                                           (start_at >= ? AND end_at <= ?)", 
                                                                           start_at, start_at, end_at, end_at, start_at, end_at] }}

  # find free appointments
  named_scope :free,        { :conditions => {:mark_as => Job::FREE} }
    
  def after_initialize
    if self.start_at and self.job_id and self.end_at.blank?
      # initialize end_at
      self.end_at = self.start_at + self.job.duration_to_seconds
    end
    
    # initialize duration
    self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
    
    if self.job
      # initialize mark_as field with job.schedule_as
      self.mark_as = self.job.schedule_as
    end
  end
  
  def validate
    if self.start_at and self.end_at
      # check that start_at happens before end_at
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
  
  def when_range=(s)
    @when_range = Chronic.parse(s, :guess => false)
    if @when_range
      self.start_at = @when_range.first
      self.end_at   = @when_range.last
    end 
  end
  
  def when_range
    @when_range
  end
  # END: time virtual attributes
  
  # allow assignment of customer attributes when creating an appointment
  # will only create a new customer if it doesn't already exist based on the 'name' field
  def customer_attributes=(customer_attributes)
    self.customer = Customer.find_by_name(customer_attributes["name"]) || self.create_customer(customer_attributes)
  end
  
  # find free time slots based on appointment [start_at, end_at]
  # valid options:
  #  :limit => limit the number of free time slots returned
  #  :job_id => return free time slots using the specified job id
  def find_free_time(options={})
    raise AppointmentInvalid if !self.valid?
    
    # parse options
    limit   = options[:limit].to_i if options[:limit]
    job_id  = options[:job_id].to_i if options[:job_id]
    
    # find free timeslots with duration >= job's duration
    duration  = self.job.duration
    timeslots = Appointment.resource(resource_id).span(start_at, end_at).duration_gt(duration).free
    
    # iterate through all available timeslots
    timeslots = timeslots.inject([]) do |array, timeslot|
      # resize timeslot if its larger than the requested free timeslot
      timeslot.start_at = self.start_at if timeslot.start_at < self.start_at
      timeslot.end_at   = self.end_at if timeslot.end_at > end_at
      timeslot.duration = (timeslot.end_at.to_i - timeslot.start_at.to_i) / 60
      
      # apply job id
      timeslot.job_id   = job_id if job_id
      
      # break timeslot into chunks based on job duration
      chunks = timeslot.duration / duration
      
      # apply limit based on current array size
      chunks = (limit - array.size) if limit
      
      0.upto(chunks-1) do |i|
        # clone timeslot, then increment start_at based on chunk index
        timeslot_i = timeslot.clone
        timeslot_i.start_at = timeslot.start_at + (i * duration).minutes
        timeslot_i.end_at   = timeslot_i.start_at + duration.minutes
        timeslot_i.duration = duration
        array << timeslot_i
      end
      
      array
    end
    
    timeslots
  end
  
  # split a free appointment into multiple appointments with the specified job and time range
  def split_free_time(job, job_start_at, job_end_at, options={})
    # validate job argument
    raise ArgumentError if job.blank? or !job.is_a?(Job)
    raise ArgumentError if self.job.schedule_as != Job::FREE

    # check that the current appointment is free
    raise AppointmentNotFree if self.mark_as != Job::FREE
    
    # convert argument Strings to ActiveSupport::TimeWithZones
    job_start_at = Time.zone.parse(job_start_at) if job_start_at.is_a?(String)
    job_end_at   = Time.zone.parse(job_end_at) if job_end_at.is_a?(String)
    
    # time arguments should now be ActiveSupport::TimeWithZone objects
    raise ArgumentError if !job_start_at.is_a?(ActiveSupport::TimeWithZone) or !job_end_at.is_a?(ActiveSupport::TimeWithZone)
        
    # check that the job_start_at and job_end_at times fall within the appointment timeslot
    raise ArgumentError unless job_start_at.between?(self.start_at, self.end_at) and job_end_at.between?(self.start_at, self.end_at)
    
    # build new appointment
    new_appt = Appointment.new(self.attributes)
    new_appt.job      = job
    new_appt.start_at = job_start_at
    new_appt.end_at   = job_end_at
    new_appt.mark_as  = job.schedule_as
    
    # build new start, end appointments
    unless job_start_at == self.start_at
      # the start appoint starts at the same time but ends when the new appoint starts
      start_appt = Appointment.new(self.attributes)
      start_appt.start_at = self.start_at
      start_appt.end_at   = new_appt.start_at
      start_appt.mark_as  = Job::FREE
    end
    
    unless job_end_at == self.end_at
      # the end appointment ends at the same time, but starts when the new appointment ends
      end_appt = Appointment.new(self.attributes)
      end_appt.start_at   = new_appt.end_at
      end_appt.end_at     = self.end_at
      end_appt.mark_as    = Job::FREE
    end
    
    appointments = [start_appt, new_appt, end_appt].compact
    
    if options[:commit].to_i == 1
      
      # commit the apointment changes
      transaction do
        # remove this appointment first
        self.destroy
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
  
  # create free time in the specified timeslot
  def self.create_free_time(company, resource, start_at, end_at)
    # make sure the timeslot is empty
    appts = Appointment.company(company.id).resource(resource.id).span(start_at, end_at)
    
    if !appts.blank?
      raise TimeslotNotEmpty
    end
    
    # find first job scheduled as 'free'
    job  = Job.free.first
    
    # create appointment - use 0 for customer_id
    appt = Appointment.create(:start_at => start_at, :end_at => end_at, :mark_as => Job::FREE, :job => job, :company => company,
                              :resource => resource, :customer_id => 0)
  end
end
