class Company < ActiveRecord::Base
  extend ActiveSupport::Memoizable
  
  # Badges for authorization
  badges_authorizable_object

  validates_uniqueness_of   :name
  validates_presence_of     :name

  # Subdomain rules
  validates_presence_of     :subdomain
  validates_format_of       :subdomain,
                            :with => /^[A-Za-z0-9-]+$/,
                            :message => 'The subdomain can only contain alphanumeric characters and dashes.',
                            :allow_blank => true
  validates_uniqueness_of   :subdomain,
                            :case_sensitive => false
  validates_exclusion_of    :subdomain,
                            :in => %w( support blog www billing help api ),
                            :message => "The subdomain <strong>{{value}}</strong> is reserved and unavailable."

  before_validation         :init_subdomain, :downcase_subdomain

  validates_presence_of     :time_zone
  has_many                  :company_schedulables
  has_many_polymorphs       :schedulables, :from => [:users], :through => :company_schedulables
  has_many                  :services
  has_many                  :products
  has_many                  :appointments
  has_many                  :customers, :through => :appointments, :uniq => true
  has_many                  :invitations
  
  # Accounting info
  has_one                   :subscription
  has_one                   :owner, :through => :subscription, :source => :user
  has_one                   :plan, :through => :subscription

  # after create filter to initialize basic services that are provided by all companies
  after_create              :init_basic_services

  def validate
    if self.subscription.blank?
      errors.add_to_base("Subscription is not valid")
    end
  end
  
  def after_initialize
    # after_initialize can also be called when retrieving objects from the database
    return unless new_record?
    
    # titleize name
    self.name = self.name.titleize unless self.name.blank?
  end
  
  # return true if the company contains the specified schedulable
  def has_schedulable?(object)
    # can't use schedulables.include?(object) here, not sure why but possibly because of polymorphic
    schedulables.any? { |o| o == object }
  end
  
  def services_count
    services.count
  end
  memoize :services_count

  def work_services_count
    services.work.count
  end
  memoize :work_services_count
  
  # returns true if the company has at least 1 schedulable and 1 work service
  def can_schedule_appointments?
    return false if schedulables_count == 0 or work_services_count == 0
    true
  end
  
  def locations_with_any
    Array(Location.anywhere) + self.locations
  end

  # Plan tests
  def may_add_location?
    self.plan.may_add_location?(self)
  end
  
  def may_add_resource?
    self.plan.may_add_resource?(self)
  end  
  
  protected

  def downcase_subdomain
    self.subdomain.downcase! if attribute_present?("subdomain")
  end
  
  # initialize subdomain based on company name
  def init_subdomain
    if !attribute_present?("subdomain")
      self.subdomain = self.name.downcase.gsub(/[^\w\d]/, '') unless name.blank?
    end
  end
  
  # initialize company's basic services
  def init_basic_services
    services.create(:name => Service::AVAILABLE, :duration => 0, :mark_as => "free", :price => 0.00)
  end
  
end
