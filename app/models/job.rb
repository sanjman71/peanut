class Job < ActiveRecord::Base
  validates_presence_of       :name, :duration
  validates_uniqueness_of     :name
  validates_inclusion_of      :schedule_as, :in => %w(free busy), :message => "jobs can only be scheduled as free or busy"
  has_many                    :appointments
  before_save                 :titleize_name
  
  # job name constants
  AVAILABLE     = "Available"
  UNAVAILABLE   = "Unavailable"
  
  # job schedule_as constants
  FREE          = 'free'      # free jobs show up as free/available time and can be scheduled
  BUSY          = 'busy'      # busy jobs can not be scheduled
  WORK          = 'work'      # work jobs are work items that can be scheduled in free timeslots
  
  named_scope :free,          { :conditions => {:schedule_as => FREE} }
  named_scope :busy,          { :conditions => {:schedule_as => BUSY} }
  named_scope :work,          { :conditions => {:schedule_as => WORK} }
  
  def duration_to_seconds
    self.duration * 60
  end
  
  private
  
  def titleize_name
    self.name = self.name.titleize
  end
  
end
