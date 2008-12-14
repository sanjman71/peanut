class AppointmentInvoice < ActiveRecord::Base
  belongs_to                :appointment
  has_many                  :line_items, :class_name => "AppointmentInvoiceLineItem"
  validates_presence_of     :appointment_id
  has_many_polymorphs       :chargeables, :from => [:products, :services], :through => :appointment_invoice_line_items
end