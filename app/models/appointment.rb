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

  # find appointments based on a named time range
  named_scope :upcoming,    { :conditions => ["start_at >= ?", Time.now] }
  named_scope :past,        { :conditions => ["start_at <= ?", Time.now] }
  
  # find appointments spanning a time range
  named_scope :span,        lambda { |start_at, end_at| { :conditions => ["(start_at < ? AND end_at > ?) OR (start_at < ? AND end_at > ?) OR 
                                                                           (start_at >= ? AND end_at <= ?)", 
                                                                           start_at, start_at, end_at, end_at, start_at, end_at] }}

  # find free, busy, work appointments
  named_scope :free,        { :conditions => {:mark_as => Job::FREE} }
  named_scope :busy,        { :conditions => {:mark_as => Job::BUSY} }
  named_scope :work,        { :conditions => {:mark_as => Job::WORK} }
    
  # valid when values
  WHENS                     = ['today', 'tomorrow', 'this week', 'next week', 'later']
  
  def after_initialize
    if self.start_at and self.job_id and self.end_at.blank?
      # initialize end_at
      self.end_at = self.start_at + self.job.duration_to_seconds
    end
    
    # initialize duration
    self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
    
    if self.job
      # initialize mark_as field with job.mark_as
      self.mark_as = self.job.mark_as
    end
  end
  
  def validate
    if @when == :error
      errors.add_to_base("When string is invalid")
    elsif @when == :blank
      errors.add_to_base("When string is empty")
    end
    
    if self.start_at and self.end_at
      # start_at must be before end_at
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
  
  def when=(s)
    if s.blank?
      @when = :blank
    elsif !WHENS.include?(s)
      @when = :unsupported
    elsif s == 'later'
      # special case, range should be 2 weeks after next week, adjusted by a day
      range         = Chronic.parse('next week', :guess => false)
      @when         = s
      self.start_at = range.last + 1.day
      self.end_at   = range.last + 1.day + 2.weeks
    else
      # parse when string
      range = Chronic.parse(s, :guess => false)
      
      if range.blank?
        @when = :error
        return
      end

      @when         = s
      self.start_at = range.first
      self.end_at   = range.last

      if s == 'this week'
        # make 'this week' end on monday 12am
        self.end_at += 1.day
      elsif s == 'next week'
        # make 'next week' go from monday to monday
        self.start_at += 1.day
        self.end_at   += 1.day
      end
    end
  end
  
  def when
    @when
  end
  # END: time virtual attributes
  
  # allow assignment of customer attributes when creating an appointment
  # will only create a new customer if it doesn't already exist based on the 'name' field
  def customer_attributes=(customer_attributes)
    self.customer = Customer.find_by_name(customer_attributes["name"]) || self.create_customer(customer_attributes)
  end
    
  # split a free appointment into multiple appointments using the specified job and time
  def split_free_time(job, job_start_at, job_end_at, options={})
    # validate job argument
    raise ArgumentError if job.blank? or !job.is_a?(Job)
    raise ArgumentError if self.job.mark_as != Job::FREE

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
    new_appt.mark_as  = job.mark_as
    
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
    appt = Appointment.create(:start_at => start_at, :end_at => end_at, :mark_as => job.mark_as, :job => job, :company => company,
                              :resource => resource, :customer_id => 0)
  end
end
