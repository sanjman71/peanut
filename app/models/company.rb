class Company < ActiveRecord::Base
  extend ActiveSupport::Memoizable
  
  # Badges for authorization
  badges_authorizable_object

  validates_uniqueness_of   :name
  validates_presence_of     :name
  validates_presence_of     :time_zone
  has_many_polymorphs       :resources, :from => [:people]
  has_many                  :services
  has_many                  :products
  has_many                  :appointments
  has_many                  :users
  has_many                  :customers, :through => :appointments, :uniq => true
  before_save               :init_subdomain

  def after_initialize
    # titleize name
    self.name = self.name.titleize unless self.name.blank?
  end
  
  def people_count
    people.count
  end
  memoize :people_count
  
  def services_count
    services.count
  end
  memoize :services_count
  
  # returns true if the company has enough people and services to schedule appointments
  def can_schedule_appointments?
    return false if people_count == 0
    return false if services_count == 0
    true
  end
  
  private
  
  # initialize subdomain based on company name
  def init_subdomain
    self.subdomain = self.name.downcase.gsub(/[^\w\d]/, '')
  end
  
end
