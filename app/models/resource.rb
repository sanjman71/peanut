class Resource < ActiveRecord::Base
  belongs_to                :company
  validates_presence_of     :company_id, :name
  validates_uniqueness_of   :name, :scopy => :company_id
end
