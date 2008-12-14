class InvoicesController < ApplicationController
  before_filter :init_current_company
  layout 'default'

  def show
    @invoice  = AppointmentInvoice.find(params[:id])
    @services = @current_company.services.work.all
  end
  
  def add
    @invoice  = AppointmentInvoice.find(params[:id])
    
    # add chargeable
    if params[:service_id]
      @chargeable = @current_company.services.find(params[:service_id])
      
      if @chargeable
        line_item = AppointmentInvoiceLineItem.new(:chargeable => @chargeable, :price_in_cents => @chargeable.price_in_cents)
        @invoice.line_items.push(line_item)
      end
    end
  end
  
  def remove
    @invoice    = AppointmentInvoice.find(params[:id])
    @line_item  = @invoice.line_items.find(params[:line_item_id])
    
    # remove line item
    @invoice.line_items.delete(@line_item)
  end
  
end