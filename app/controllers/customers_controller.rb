class CustomersController < ApplicationController
  before_filter :disable_global_flash, :only => [:index]

  privilege_required 'read users', :only => [:index], :on => :current_company

  # GET /customers
  def index
    @search = params[:search]
    @role   = Company.customer_role
    
    if !@search.blank?
      @customers    = current_company.authorized_users.with_role(@role).search_by_name(@search).order_by_name
      @search_text  = "Customers matching '#{@search}'"
    else
      @customers    = current_company.authorized_users.with_role(@role).order_by_name
      @search_text  = @customers.blank? ? "No Customers" : "All Customers"
    end
    
    # check if current user is a company manager
    @company_manager = company_manager?
    
    respond_to do |format|
      format.html
      format.js
      format.json { render(:json => @customers.to_json(:only => ['id', 'name', 'email'])) }
    end
  end

  # GET /customers/1
  def show
    @customer = User.find(params[:id])
    @note     = Note.new
    
    # build notes collection, most recent first
    @notes    = @customer.notes.sort_recent

    respond_to do |format|
      format.html
    end
  end

end
