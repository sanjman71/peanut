class Plan < ActiveRecord::Base
  has_many :accounts, :through => :plan_subscriptions
  has_many :companies, :through => :plan_subscriptions
  
  def is_eligible(company)
    (
      (self.max_locations.blank? || (company.locations.size <= self.max_locations)) &&
      (self.max_resources.blank? || (company.resources.size <= self.max_resources))
    )
  end
  
  def may_add_location?(company)
    (self.max_locations.blank? || (company.locations.size < self.max_locations))
  end
  
  def may_add_resource?(company)
    (self.max_resources.blank? || (company.resources.size < self.max_resources))
  end
  
end
