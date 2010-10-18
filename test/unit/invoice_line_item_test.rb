require 'test_helper'

class InvoiceLineItemTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :invoice_id
  should_validate_presence_of   :chargeable_type
  should_validate_presence_of   :chargeable_id
  should_validate_presence_of   :price_in_cents
  
end
