class Job < ActiveRecord::Base
  validates_presence_of       :name, :duration
  validates_uniqueness_of     :name
  has_many                    :appointments
  before_save                 :titleize_name
  
  # job name constants
  AVAILABLE     = "Available"
  UNAVAILABLE   = "Unavailable"
  
  named_scope :available,     { :conditions => {:name => AVAILABLE} }
  named_scope :unavailable,   { :conditions => {:name => UNAVAILABLE} }
  
  named_scope :names,         { :select => :name, :order => :name }
  
  def duration_to_seconds
    self.duration * 60
  end
  
  private
  
  def titleize_name
    self.name = self.name.titleize
  end
  
end
