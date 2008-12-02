class Service < ActiveRecord::Base
  validates_presence_of       :company_id, :name, :duration, :price_in_cents
  validates_uniqueness_of     :name, :scope => :company_id
  validates_inclusion_of      :mark_as, :in => %w(free busy work), :message => "services can only be scheduled as free, busy or work"
  belongs_to                  :company
  has_many                    :appointments
  has_many_polymorphs         :resources, :from => [:people]
  before_save                 :titleize_name
  
  # name constants
  AVAILABLE                   = "Available"
  UNAVAILABLE                 = "Unavailable"
  
  named_scope :free,          { :conditions => {:mark_as => Appointment::FREE} }
  named_scope :busy,          { :conditions => {:mark_as => Appointment::BUSY} }
  named_scope :work,          { :conditions => {:mark_as => Appointment::WORK} }
  
  def self.nothing(options={})
    r = Service.new do |o|
      o.name = options[:name] || ""
      o.send(:id=, 0)
    end
  end
  
  # return true if its the special service 'nothing'
  def nothing?
    self.id == 0
  end
  
  def duration_to_seconds
    self.duration * 60
  end
  
  private
  
  def titleize_name
    self.name = self.name.titleize
  end
  
end
