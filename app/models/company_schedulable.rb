class CompanySchedulable < ActiveRecord::Base
  belongs_to                :company, :counter_cache => :schedulables_count
  belongs_to                :schedulable, :polymorphic => true
  validates_presence_of     :company_id, :schedulable_id, :schedulable_type
  
  named_scope :find_by_schedulable, lambda { |o| {:conditions => { :schedulable_id => o.id, :schedulable_type => o.class.to_s.tableize } }}
end
