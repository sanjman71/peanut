class Service < ActiveRecord::Base
  validates_presence_of       :company_id, :name, :duration
  validates_uniqueness_of     :name, :scope => :company_id
  validates_inclusion_of      :mark_as, :in => %w(free busy), :message => "services can only be scheduled as free or busy"
  belongs_to                  :company
  has_many                    :appointments
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
  
  def duration_to_seconds
    self.duration * 60
  end
  
  private
  
  def titleize_name
    self.name = self.name.titleize
  end
  
end
