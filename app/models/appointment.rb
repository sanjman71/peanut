# define exception classes
class AppointmentNotFree < Exception; end
class TimeslotNotEmpty < Exception; end
class AppointmentInvalid < Exception; end

class Appointment < ActiveRecord::Base
  belongs_to              :company
  belongs_to              :service
  belongs_to              :resource, :polymorphic => true
  belongs_to              :service
  belongs_to              :customer
  validates_presence_of   :company_id, :service_id, :resource_id, :resource_type, :customer_id, :start_at, :end_at
  validates_inclusion_of  :mark_as, :in => %w(free busy work wait)
  has_one                 :invoice, :class_name => "AppointmentInvoice", :dependent => :destroy
  before_save             :make_confirmation_code
  
  # appointment mark_as constants
  FREE                    = 'free'      # free appointments show up as free/available time and can be scheduled
  BUSY                    = 'busy'      # busy appointments can not be scheduled
  WORK                    = 'work'      # work appointments are items that can be scheduled in free timeslots
  WAIT                    = 'wait'      # wait appointments are waiting be scheduled in free timeslots
  
  # appointment confirmation code constants
  CONFIRMATION_CODE_ZERO  = '00000'
  
  named_scope :service,     lambda { |id| { :conditions => {:service_id => id} }}
  named_scope :resource,    lambda { |resource| { :conditions => {:resource_id => resource.id, :resource_type => resource.class.to_s} }}
  named_scope :customer,    lambda { |id| { :conditions => {:customer_id => id} }}
  named_scope :duration_gt, lambda { |t|  { :conditions => ["duration >= ?", t] }}

  # find appointments based on a named time range
  named_scope :upcoming,    { :conditions => ["start_at >= ?", Time.now] }
  named_scope :past,        { :conditions => ["start_at <= ?", Time.now] }
  
  # find appointments overlapping a time range
  named_scope :overlap,       lambda { |start_at, end_at| { :conditions => ["(start_at < ? AND end_at > ?) OR (start_at < ? AND end_at > ?) OR 
                                                                             (start_at >= ? AND end_at <= ?)", 
                                                                             start_at, start_at, end_at, end_at, start_at, end_at] }}

  # find appointments overlapping a time of day range
  named_scope :time_overlap,  lambda { |time_range| { :conditions => ["(time_start_at < ? AND time_end_at > ?) OR 
                                                                       (time_start_at < ? AND time_end_at > ?) OR 
                                                                       (time_start_at >= ? AND time_end_at <= ?)", 
                                                                       time_range.first, time_range.first, 
                                                                       time_range.last, time_range.last, 
                                                                       time_range.first, time_range.last] }}

  # find appointments by mark_as value
  named_scope :free,        { :conditions => {:mark_as => FREE} }
  named_scope :busy,        { :conditions => {:mark_as => BUSY} }
  named_scope :work,        { :conditions => {:mark_as => WORK} }
  named_scope :wait,        { :conditions => {:mark_as => WAIT} }
  named_scope :free_work,   { :conditions => ["mark_as = ? OR mark_as = ?", FREE, WORK]}
  
  # find appointments by state, eager load the associated invoice for completed appointments
  named_scope :completed,   { :include => :invoice, :conditions => {:state => 'completed'} }
  named_scope :upcoming,    { :conditions => {:state => 'upcoming'} }

  # valid when values
  WHEN_THIS_WEEK            = 'this week'
  WHENS                     = ['today', 'tomorrow', WHEN_THIS_WEEK, 'next week', 'later']
  WHEN_WEEKS                = [WHEN_THIS_WEEK, 'next week', 'later']
  WHENS_EXTENDED            = ['today', 'tomorrow', WHEN_THIS_WEEK, 'next week', 'next 2 weeks', 'this month', 'later']
  
  # valid time of day values
  TIMES                     = ['anytime', 'morning', 'afternoon', 'evening']

  # convert time of day to a seconds range
  TIMES_HASH                = {'anytime'    => [0,        24*3600],     # entire day
                               'morning'    => [8*3600,   12*3600],     # 8am - 12pm
                               'afternoon'  => [12*3600,  17*3600],     # 12pm - 5pm
                               'evening'    => [17*3600,  21*3600],     # 5pm - 9pm
                               'never'      => [0,        0]
                              }

  # BEGIN acts_as_state_machhine
  include AASM
  
  aasm_column           :state
  aasm_initial_state    :upcoming
  aasm_state            :upcoming
  aasm_state            :completed
  aasm_state            :canceled
  
  aasm_event :checkout do
    transitions :to => :completed, :from => [:upcoming]
  end

  aasm_event :cancel do
    transitions :to => :canceled, :from => [:upcoming]
  end
  # END acts_as_state_machine

  # TODO - this overrides and fixes a bug in Rails 2.2 - ticket http://rails.lighthouseapp.com/projects/8994/tickets/1339
  def self.create_time_zone_conversion_attribute?(name, column)
    # Appointment.write_inheritable_attribute(:skip_time_zone_conversion_for_attributes, [])
    time_zone_aware_attributes && skip_time_zone_conversion_for_attributes && !skip_time_zone_conversion_for_attributes.include?(name.to_sym) && [:datetime, :timestamp].include?(column.type)
  end
  
  # map time of day string to a utc time range in seconds
  def self.time_range(s)
    array = (TIMES_HASH[s] || TIMES_HASH['never']).map { |x| x - Time.zone.utc_offset }
    Range.new(array[0], array[1])
  end
  
  def after_initialize
    # after_initialize can also be called when retrieving objects from the database
    return unless new_record?
    
    if self.start_at and self.service and self.end_at.blank?
      # initialize end_at
      self.end_at = self.start_at + self.service.duration_to_seconds
    end
    
    # initialize duration
    self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
    
    # initialize mark_as if its blank
    if self.mark_as.blank? and self.service
      self.mark_as = self.service.mark_as
    end
    
    # initialize when, time attributes

    if self.when.nil?
      self.when = ''
    end

    if self.time.nil?
      self.time = ''
    end
    
    # initialize time of day attributes
    
    if self.mark_as == WAIT
      # special case of a waitlist appointment
      if self.when == 'this week'
        # set start_at to beginning of day
        self.start_at = self.start_at.beginning_of_day
      end

      # set time of day values based on time value
      time_range          = Appointment.time_range(self.time)
      self.time_start_at  = time_range.first
      self.time_end_at    = time_range.last
    else
      # set time of day values based on appointment start, end times
      if self.start_at
        self.time_start_at = self.start_at.utc.hour * 3600 + self.start_at.min * 60
      end

      if self.end_at
        self.time_end_at = self.end_at.utc.hour * 3600 + self.end_at.min * 60
      end
    end
  end
  
  def validate
    if self.when == :error
      errors.add_to_base("When is invalid")
    elsif self.when == :blank
      # errors.add_to_base("When is empty")
    end

    if self.time == :error
      errors.add_to_base("Time is invalid")
    elsif self.time == :blank
      # errors.add_to_base("Time is empty")
    end
    
    if self.start_at and self.end_at
      # start_at must be before end_at
      if !(start_at.to_i < end_at.to_i)
        errors.add_to_base("Appointment start time must be earlier than the apointment end time")
      end
    end
    
    if self.resource
      # resource must belong to the same company
      if !self.resource.companies.include?(self.company)
        errors.add_to_base("Resource is not associated to this company")
      end
    end
    
    if self.service
      # service must belong to the same company
      if self.service.company_id != self.company_id
        errors.add_to_base("Service is not offered by this company")
      end
    end
  end
  
  # START: override attribute methods
  def when=(s)
    if s.blank?
      # when can be empty
      write_attribute(:when, '')
    elsif !WHENS.include?(s)
      write_attribute(:when , :error)
    elsif s == 'later'
      write_attribute(:when, s)
      # special case, range should be 2 weeks after next week, adjusted by a day
      range         = Chronic.parse('next week', :guess => false)
      self.start_at = range.last + 1.day
      self.end_at   = range.last + 1.day + 2.weeks
    else
      # parse when string
      range = Chronic.parse(s, :guess => false)
      
      if range.blank?
        write_attribute(:when, :error)
        return
      end

      write_attribute(:when, s)
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
  
  def time=(s)
    if s.blank?
      # time can be empty
      write_attribute(:time, '')
    elsif TIMES.include?(s)
      write_attribute(:time, s)
    else 
      # invalid time
      write_attribute(:time, :error)
    end
  end
  
  def time(options = {})
    @time = read_attribute(:time)
    if @time.blank? and options[:default]
      # return default value
      return options[:default]
    end
    @time
  end
  
  # END: override attribute methdos
  
  # START: appointment virtual attributes
  def start_at_string
    self.start_at.to_s
  end
  
  def start_at_string=(s)
    # chronic parses times into the current time zone,
    # but its stored by activerecord in utc format
    self.start_at = Chronic.parse(s)
  end

  def end_at_string
    self.end_at.to_s
  end
  
  def end_at_string=(s)
    # chronic parses times into the current time zone,
    # but its stored by activerecord in utc format
    self.end_at = Chronic.parse(s)
  end
  
  def time_range=(attributes)
    time_range      = TimeRange.new(attributes)
    self.start_at   = time_range.start_at
    self.end_at     = time_range.end_at
  end
  
  def time_range
    Range.new(time_start_at, time_end_at)
  end
  # END: time virtual attributes
  
  # allow assignment of customer attributes when creating an appointment
  # will only create a new customer if it doesn't already exist based on the 'email' field
  def customer_attributes=(customer_attributes)
    self.customer = Customer.find_by_email(customer_attributes["email"]) || self.create_customer(customer_attributes)
  end
      
  # returns all appointment conflicts
  # conflict rules:
  #  - resource must be the same
  #  - start, end times must overlap
  #  - must be marked as 'free' or 'work'
  def conflicts
    @conflicts ||= self.company.appointments.free_work.resource(resource).overlap(start_at, end_at)
  end
  
  # returns true if this appointment conflicts with any other
  def conflicts?
    self.conflicts.size > 0
  end
  
  # return true if the appointment is on the waitlist
  def waitlist?
    self.mark_as == WAIT
  end
  
  # return the collection of waitlist appointments that overlap with a free appointment
  def waitlist
    return [] if self.mark_as != FREE
    # find wait appointments that overlap in both date and time ranges
    @waitlist ||= self.company.appointments.wait.overlap(start_at, end_at).time_overlap(self.time_range)
  end
  
  # narrow an appointment by start, end times
  def narrow_by_time_range!(start_at, end_at)
    # validate start, end times
    raise AppointmentInvalid, "invalid narrow time range" if start_at > self.end_at or end_at < self.start_at or start_at > end_at
    
    # narrow appointment by start, end time
    self.start_at       = start_at if self.start_at < start_at
    self.end_at         = end_at if self.end_at > end_at
    self.duration       = (self.end_at.to_i - self.start_at.to_i) / 60
    
    # adjust time start, end values
    self.time_start_at  = self.start_at.utc.hour * 3600 + self.start_at.min * 60
    self.time_end_at    = self.end_at.utc.hour * 3600 + self.end_at.min * 60
  end
  
  # narrow an appointment by time of day
  def narrow_by_time_of_day!(time)
    return if time == 'anytime'
    
    request_time_range = Appointment.time_range(time)
    current_time_range = Range.new(self.time_start_at, self.time_end_at)
    
    if current_time_range.overlap?(request_time_range)
      # narrow
      if current_time_range.include?(request_time_range)
        # find and adjust by the difference in seconds
        self.start_at += (request_time_range.first - current_time_range.first).seconds
        self.end_at   += (request_time_range.last - current_time_range.last).seconds
      elsif current_time_range.include?(request_time_range.first)
        # first part of request time range overlaps
        self.start_at += (request_time_range.first - current_time_range.first)
      else
        # last part of request time range overlaps
        self.end_at   += (request_time_range.last - current_time_range.last).seconds
      end
      # adjust duration
      self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
      # check special case of 0 duration
      self.start_at = nil if duration == 0
      self.end_at   = nil if duration == 0
    else
      # the requested range does not overlap - narrow to an empty appointment
      self.start_at       = nil
      self.end_at         = nil
      self.time_start_at  = nil
      self.time_end_at    = nil
      self.duration       = 0
    end
  end
  
  # split appointment into timeslots of the specified duration
  def timeslots(duration, options={})
    chunks = self.duration / duration
    
    # apply limit based on current array size
    # chunks = (limit - array.size) if limit
    
    timeslots = Range.new(0,chunks-1).inject([]) do |collection, i|
      # clone timeslot, then increment start_at based on chunk index
      start_at_i = self.start_at + (i * duration).minutes
      end_at_i   = start_at_i + duration.minutes
      timeslot_i = AppointmentTimeslot.new(:appointment => self, :start_at => start_at_i, :end_at => end_at_i)
      collection << timeslot_i
    end
    
    timeslots
  end
  
  protected
  
  def make_confirmation_code
    unless self.confirmation_code
      if [WORK, WAIT].include?(self.mark_as)
        # create a random string
        possible_values         = ('A'..'Z').to_a + (0..9).to_a
        code_length             = 5
        self.confirmation_code  = (0...code_length).map{ possible_values[rand(possible_values.size)]}.join
      else
        # use a constant string
        self.confirmation_code  = CONFIRMATION_CODE_ZERO
      end
    end
  end
  
end
