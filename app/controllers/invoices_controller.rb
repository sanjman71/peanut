class InvoicesController < ApplicationController

  # /invoices
  # /invoices/when/past-2-weeks
  # /invoices/range/20090101..20090201
  def index
    if params[:start_date] and params[:end_date]
      # build daterange using range values
      @start_date   = params[:start_date]
      @end_date     = params[:end_date]
      @daterange    = DateRange.parse_range(@start_date, @end_date)
    else
      # build daterange using when
      @when         = (params[:when] || Appointment::WHEN_PAST_WEEK).from_url_param
      @daterange    = DateRange.parse_when(@when)
    end
    
    # find all invoices for completed appointments, restricted by daterange
    @appointments = @current_company.appointments.completed.overlap(@daterange.start_at, @daterange.end_at).all(:order => 'start_at ASC')
    @total        = @appointments.inject(Money.new(0)) { |total, appt| total += appt.invoice.total_as_money }
  end
  
  # /invoices/search
  # params[:start_date], params[:end_date]
  def search
    # reformat start_date, end_date strings, and redirect to index action
    start_date  = sprintf("%s", params[:start_date].split('/').reverse.swap!(1,2).join)
    end_date    = sprintf("%s", params[:end_date].split('/').reverse.swap!(1,2).join)
    redirect_to url_for(:action => 'index', :start_date => start_date, :end_date => end_date, :subdomain => @subdomain)
  end
  
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