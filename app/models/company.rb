class Company < ActiveRecord::Base
  validates_uniqueness_of   :name
  validates_presence_of     :name
  has_many                  :resources
  before_save               :init_subdomain
  
  private
  
  # initialize subdomain based on company name
  def init_subdomain
    self.subdomain = self.name.downcase.gsub(/[^\w\d]/, '')
  end
  
end
