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
  after_create              :init_basic_services
  
  def after_initialize
    # after_initialize can also be called when retrieving objects from the database
    return unless new_record?
    
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

  def work_services_count
    services.work.count
  end
  memoize :work_services_count
  
  # returns true if the company has at least 1 person and 1 work service
  def can_schedule_appointments?
    return false if people_count == 0 or work_services_count == 0
    true
  end
  
  def locations_with_any
    Array(Location.anywhere) + self.locations
  end
  
  
  private
  
  # initialize subdomain based on company name
  def init_subdomain
    self.subdomain = self.name.downcase.gsub(/[^\w\d]/, '')
  end
  
  # initialize company's basic services
  def init_basic_services
    services.create(:name => Service::AVAILABLE, :duration => 0, :mark_as => "free", :price => 0.00)
  end
  
end
