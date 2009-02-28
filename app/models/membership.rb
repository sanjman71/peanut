class Membership < ActiveRecord::Base
  belongs_to                :service, :counter_cache => :resources_count
  belongs_to                :resource, :polymorphic => true, :counter_cache => :services_count
  validates_presence_of     :service_id, :resource_id, :resource_type
  
  def validate
    if self.resource.blank?
      errors.add_to_base("Resource is invalid")
    end
    
    if self.service.blank?
      errors.add_to_base("Resource is invalid")
    end
  end
  
end
