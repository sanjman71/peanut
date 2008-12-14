class Product < ActiveRecord::Base
  belongs_to                :company
  validates_presence_of     :company_id, :name, :stock_count, :price_in_cents
end