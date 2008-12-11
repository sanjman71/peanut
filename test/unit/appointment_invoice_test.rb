require 'test/test_helper'
require 'test/factories'

class AppointmentInvoiceTest < ActiveSupport::TestCase
  
  # shoulda
  should_require_attributes :appointment_id
  
  def test_invoice
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
    customer  = Factory(:customer)
    
    # create appointment
    appt = Appointment.create(:company => company,
                              :service => haircut,
                              :resource => johnny,
                              :customer => customer,
                              :start_at_string => "today 2 pm")
    assert appt.valid?
    
    # create invoice
    appt.invoice  = AppointmentInvoice.create
    invoice       = appt.invoice
    
    assert appt.invoice.valid?
    assert_equal [], invoice.line_items
    
    # create service line item
    li1 = AppointmentInvoiceLineItem.new(:chargeable => haircut, :price_in_cents => 500)
    invoice.line_items.push(li1)
    assert_equal haircut, li1.chargeable
    assert_equal [li1], invoice.line_items
    
    # create product line items
    shampoo = Factory(:product, :name => "Shampoo", :company => company)
    li2     = AppointmentInvoiceLineItem.new(:chargeable => shampoo, :price_in_cents => 500)
    invoice.line_items.push(li2)
    assert_equal shampoo, li2.chargeable
    assert_equal [li1, li2], invoice.line_items
    
    # remove line item
    invoice.line_items.delete(li2)
    invoice.reload
    assert_equal [li1], invoice.line_items
  end
  
end
