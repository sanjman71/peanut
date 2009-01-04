class InvoiceLineItemsController < ApplicationController
  before_filter :init_current_company
  layout 'blueprint'

  def update
    @invoice_line_items = AppointmentInvoiceLineItem.find(params[:id])
    @invoice            = @invoice_line_items.appointment_invoice
    @services           = @current_company.services.work.all
    @products           = @current_company.products.instock
    
    # update line item
    @invoice_line_items.update_attributes(params[:item])
    
    respond_to do |format|
      format.js { render :template => "invoices/add_remove.js.rjs"}
    end
  end

end