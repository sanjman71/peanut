class AppointmentInvoice < ActiveRecord::Base
  belongs_to                :appointment
  validates_presence_of     :appointment_id
  has_many                  :line_items, :class_name => "AppointmentInvoiceLineItem", :dependent => :destroy
  has_many_polymorphs       :chargeables, :from => [:products, :services], :through => :appointment_invoice_line_items

  # find invoices for completed appointments
  named_scope :completed,   { :include => :appointment, :conditions => {'appointments.state' => 'completed'} }
  
  def total
    line_items.inject(0) do |sum, item|
      sum += item.price_in_cents
    end
  end
  
  def total_as_money
    Money.new(self.total / 100.0)
  end
  
end