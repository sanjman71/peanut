class CompaniesResource < ActiveRecord::Base
  belongs_to                :company
  belongs_to                :resource, :polymorphic => true
  validates_presence_of     :company_id
end
