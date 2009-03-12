class CompanySchedulable < ActiveRecord::Base
  belongs_to                :company, :counter_cache => :schedulables_count
  belongs_to                :schedulable, :polymorphic => true
  validates_presence_of     :company_id, :schedulable_id, :schedulable_type
end
