class Service < ActiveRecord::Base
  validates_presence_of       :name, :duration, :price_in_cents
  validates_inclusion_of      :duration, :in => 1..24*60*7, :message => "must be a non-zero reasonable value"
  validates_inclusion_of      :mark_as, :in => %w(free work), :message => "can only be scheduled as free or work"
  has_many                    :company_services
  has_many                    :companies, :through => :company_services
  has_many                    :appointments
  has_many_polymorphs         :schedulables, :from => [:users], :through => :service_providers
  before_validation           :init_duration
  before_save                 :titleize_name
  
  # name constants
  AVAILABLE                   = "Available"
  UNAVAILABLE                 = "Unavailable"
  
  named_scope :free,          { :conditions => {:mark_as => Appointment::FREE} }
  named_scope :work,          { :conditions => {:mark_as => Appointment::WORK} }
  
  # default duration value
  @@default_duration          = 30
  
  def self.nothing(options={})
    r = Service.new do |o|
      o.name = options[:name] || ""
      o.send(:id=, 0)
      o.duration = 0
      o.allow_custom_duration = false
    end
  end
    
  # return true if its the special service 'nothing'
  def nothing?
    self.id == 0
  end
  
  def duration_to_seconds
    self.duration * 60
  end
  
  # return true if the service is provided by the specfied provider
  def provided_by?(o)
    # can't use schedulables.include?(o) here, not sure why but possibly because of polymorphic
    schedulables.any? { |schedulable| schedulable == o }
  end
  
  def free?
    self.mark_as == Appointment::FREE    
  end
  
  def work?
    self.mark_as == Appointment::FREE    
  end

  private
  
  def init_duration
    self.duration = @@default_duration if self.duration.blank? or self.duration == 0
  end
  
  def titleize_name
    self.name = self.name.titleize
  end
  
end
