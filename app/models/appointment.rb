# define exception classes
class AppointmentNotFree < Exception; end
class TimeslotNotEmpty < Exception; end
class AppointmentInvalid < Exception; end

class Appointment < ActiveRecord::Base
  belongs_to              :company
  belongs_to              :service
  belongs_to              :person
  belongs_to              :service
  belongs_to              :customer
  validates_presence_of   :company_id, :service_id, :person_id, :customer_id, :start_at, :end_at, :confirmation_code
  validates_inclusion_of  :mark_as, :in => %w(free busy work)
  
  # appointment mark_as constants
  FREE                    = 'free'      # free appointments show up as free/available time and can be scheduled
  BUSY                    = 'busy'      # busy appointments can not be scheduled
  WORK                    = 'work'      # work appointments are items that can be scheduled in free timeslots
  
  
  named_scope :service,     lambda { |id| { :conditions => {:service_id => id} }}
  named_scope :person,      lambda { |id| { :conditions => {:person_id => id} }}
  # named_scope :people,      lambda { |*args| { :conditions => ["person_id IN (?)", (*args.first || 0)] }}  # is this somewhat correct?
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
  named_scope :free,        { :conditions => {:mark_as => FREE} }
  named_scope :busy,        { :conditions => {:mark_as => BUSY} }
  named_scope :work,        { :conditions => {:mark_as => WORK} }
  named_scope :free_work,   { :conditions => ["mark_as = ? OR mark_as = ?", FREE, WORK]}
  
  # valid when values
  WHEN_THIS_WEEK            = 'this week'
  WHENS                     = ['today', 'tomorrow', WHEN_THIS_WEEK, 'next week', 'later']
  WHEN_WEEKS                = [WHEN_THIS_WEEK, 'next week', 'later']
  WHENS_EXTENDED            = ['today', 'tomorrow', WHEN_THIS_WEEK, 'next week', 'next 2 weeks', 'this month', 'later']
  
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
  
  def after_initialize
    if self.start_at and self.service and self.end_at.blank?
      # initialize end_at
      self.end_at = self.start_at + self.service.duration_to_seconds
    end
    
    # initialize duration
    self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
    
    if self.service
      # initialize mark_as field with service.mark_as
      self.mark_as = self.service.mark_as
    end

    # initialize confirmation code
    self.make_confirmation_code
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
    
    if self.person
      # person must belong to the same company
      if !self.person.companies.include?(self.company)
        errors.add_to_base("Person is not associated to this company")
      end
    end
    
    if self.service
      # service must belong to the same company
      if self.service.company_id != self.company_id
        errors.add_to_base("Service is not offered by this company")
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
  
  def time_range=(attributes)
    time_range      = TimeRange.new(attributes)
    self.start_at   = time_range.start_at
    self.end_at     = time_range.end_at
  end
  # END: time virtual attributes
  
  # allow assignment of customer attributes when creating an appointment
  # will only create a new customer if it doesn't already exist based on the 'email' field
  def customer_attributes=(customer_attributes)
    self.customer = Customer.find_by_email(customer_attributes["email"]) || self.create_customer(customer_attributes)
  end
    
  # returns all appointment conflicts
  def conflicts
    @conflicts ||= self.company.appointments.person(person.id).span(start_at, end_at)
  end
  
  # returns true if this appointment conflicts with any other
  def conflicts?
    self.conflicts.size > 0
  end
  
  protected
  
  def make_confirmation_code
    unless self.confirmation_code
      self.confirmation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
  end
  
end
