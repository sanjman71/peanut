require 'test/test_helper'
require 'test/factories'

class ProductTest < ActiveSupport::TestCase

  # shoulda
  should_require_attributes :company_id
  should_require_attributes :name
  should_require_attributes :stock_count
  should_require_attributes :price_in_cents

end
