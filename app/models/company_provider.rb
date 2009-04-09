class CompanyProvider < ActiveRecord::Base
  belongs_to                :company, :counter_cache => :providers_count
  belongs_to                :provider, :polymorphic => true
  validates_presence_of     :company_id, :provider_id, :provider_type
end
