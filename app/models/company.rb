class Company < ActiveRecord::Base

  # Badges for authorization
  badges_authorizable_object

  validates_uniqueness_of   :name
  validates_presence_of     :name
  has_many_polymorphs       :resources, :from => [:people]
  has_many                  :services
  has_many                  :products
  has_many                  :appointments
  has_many                  :customers, :through => :appointments, :uniq => true
  before_save               :init_subdomain
  
  private
  
  # initialize subdomain based on company name
  def init_subdomain
    self.subdomain = self.name.downcase.gsub(/[^\w\d]/, '')
  end
  
end
