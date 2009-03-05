class ServiceProvider < ActiveRecord::Base
  belongs_to                :service, :counter_cache => :schedulables_count
  belongs_to                :schedulable, :polymorphic => true, :counter_cache => :services_count
  validates_presence_of     :service_id, :schedulable_id, :schedulable_type
  
  def validate
    if self.schedulable.blank?
      errors.add_to_base("schedulable is invalid")
    end
    
    if self.service.blank?
      errors.add_to_base("Service is invalid")
    end
  end
  
end
