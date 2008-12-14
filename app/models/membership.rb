class Membership < ActiveRecord::Base
  belongs_to                :service
  belongs_to                :resource, :polymorphic => true
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
