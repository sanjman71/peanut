class InvoicesController < ApplicationController
  before_filter :init_current_company

  def show
    @invoice      = AppointmentInvoice.find(params[:id])
    @appointment  = @invoice.appointment
    @mode         = @appointment.state == 'upcoming' ? :rw : :r
    @services     = @current_company.services.work.all
    @products     = @current_company.products.instock
  end
  
  def add
    @invoice      = AppointmentInvoice.find(params[:id])
    @services     = @current_company.services.work.all
    @products     = @current_company.products.instock
    
    # add chargeable
    if params[:service_id]
      @chargeable = @current_company.services.find(params[:service_id])
    elsif params[:product_id]
      @chargeable = @current_company.products.instock.find(params[:product_id])
    end
      
    if @chargeable
      # add chargeable to invoice
      @line_item = AppointmentInvoiceLineItem.new(:chargeable => @chargeable, :price_in_cents => @chargeable.price_in_cents)
      @invoice.line_items.push(@line_item)
      
      # update chargeable's inventory count
      @chargeable.inventory_remove!(1) if @chargeable.respond_to?(:inventory_remove!)
    end
    
    respond_to do |format|
      format.js { render :action => 'add_remove' }
    end
  end
  
  def remove
    @invoice      = AppointmentInvoice.find(params[:id])
    @line_item    = @invoice.line_items.find(params[:line_item_id])
    @chargeable   = @line_item.chargeable
    @services     = @current_company.services.work.all
    @products     = @current_company.products.instock
    
    # remove line item
    @invoice.line_items.delete(@line_item)

    # update chargeable's inventory count
    @chargeable.inventory_add!(1) if @chargeable.respond_to?(:inventory_add!)

    respond_to do |format|
      format.js { render :action => 'add_remove' }
    end
  end
  
end