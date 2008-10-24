class Job < ActiveRecord::Base
  validates_presence_of :name, :duration
  validates_uniqueness_of :name
  before_save :titleize_name
  
  # required available, unavailable jobs
  def self.available
    "Available"
  end
  
  def self.unavailable
    "Unavailabe"
  end
  
  
  private
  
  def titleize_name
    self.name = self.name.titleize
  end
  
end
