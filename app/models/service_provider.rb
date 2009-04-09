class ServiceProvider < ActiveRecord::Base
  belongs_to                :service, :counter_cache => :providers_count
  belongs_to                :provider, :polymorphic => true, :counter_cache => :services_count
  validates_presence_of     :service_id, :provider_id, :provider_type
  
  def validate
    if self.provider.blank?
      errors.add_to_base("provider is invalid")
    end
    
    if self.service.blank?
      errors.add_to_base("Service is invalid")
    end
  end
  
end
