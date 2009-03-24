require 'test/test_helper'
require 'test/factories'

class InvoiceLineItemTest < ActiveSupport::TestCase
  
  # shoulda
  should_require_attributes :invoice_id
  should_require_attributes :chargeable_type
  should_require_attributes :chargeable_id
  should_require_attributes :price_in_cents
  
end
