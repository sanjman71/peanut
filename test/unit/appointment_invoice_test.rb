require 'test/test_helper'
require 'test/factories'

class AppointmentInvoiceTest < ActiveSupport::TestCase
  
  # shoulda
  should_require_attributes :appointment_id
  
  def test_invoice
    company   = Factory(:company)
    johnny    = Factory(:person, :name => "Johnny", :companies => [company])
    haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price_in_cents => 500)
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
    
    # invoice should have a line item for the appointment service
    assert appt.invoice.valid?
    assert_equal 1, invoice.line_items.size
    assert_equal 500, invoice.total
    assert_equal 500, invoice.total_as_money.cents
    li1 = invoice.line_items.first
    assert_equal haircut, li1.chargeable
    
    # create product line items
    shampoo = Factory(:product, :name => "Shampoo", :company => company)
    li2     = AppointmentInvoiceLineItem.new(:chargeable => shampoo, :price_in_cents => 375)
    invoice.line_items.push(li2)
    assert_equal shampoo, li2.chargeable
    assert_equal [li1, li2], invoice.line_items
    assert_equal 875, invoice.total
    assert_equal 875, invoice.total_as_money.cents
    
    # remove line item
    invoice.line_items.delete(li2)
    invoice.reload
    assert_equal [li1], invoice.line_items
    assert_equal 500, invoice.total
    assert_equal 500, invoice.total_as_money.cents
  end
  
end
