class Membership < ActiveRecord::Base
  belongs_to                :service
  belongs_to                :resource, :polymorphic => true
  validates_presence_of     :service_id, :resource_id, :resource_type
end
