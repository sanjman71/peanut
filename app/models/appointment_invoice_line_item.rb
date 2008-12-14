class AppointmentInvoiceLineItem < ActiveRecord::Base
  belongs_to                :chargeable, :polymorphic => true
  belongs_to                :appointment_invoice
  
  validates_presence_of     :appointment_invoice_id, :price_in_cents, :chargeable_type, :chargeable_id
end