require 'test/test_helper'
require 'test/factories'

class ProductTest < ActiveSupport::TestCase

  should_require_attributes :company_id
  should_require_attributes :name
  should_require_attributes :inventory
  should_require_attributes :price_in_cents
  
  should_belong_to          :company
  
  def test_should_change_inventory
    company = Factory(:company)
    product = Factory(:product, :inventory => 5, :company => company)
    assert product.valid?
    assert_equal 5, product.inventory
    
    # add inventory
    product.inventory_add!(3)
    assert_equal 8, product.inventory
    assert_equal true, product.stocked?
    
    # remove inventory
    product.inventory_remove!(5)
    assert_equal 3, product.inventory

    product.inventory_remove!(3)
    assert_equal 0, product.inventory
    assert_equal false, product.stocked?
  end
  
end
