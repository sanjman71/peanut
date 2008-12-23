class Product < ActiveRecord::Base
  belongs_to                :company
  validates_presence_of     :company_id, :name, :inventory, :price_in_cents
  validates_uniqueness_of   :name, :scope => :company_id

  # products with inventory > 0
  named_scope :instock,         { :conditions => ["inventory > 0"] }

  # products with inventory == 0
  named_scope :outofstock,      { :conditions => ["inventory = 0"] }
end