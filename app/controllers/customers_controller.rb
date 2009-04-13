class CustomersController < ApplicationController

  privilege_required 'read users', :only => [:index], :on => :current_company

  @@per_page  = 10
  
  # GET /customers
  def index
    @search = params[:search]
    @role   = Company.customer_role
    
    if !@search.blank?
      @customers    = current_company.authorized_users.with_role(@role).search_by_name(@search).order_by_name
      @search_text  = "Customers matching '#{@search}'"
      @paginate     = false
    else
      @customers    = current_company.authorized_users.with_role(@role).order_by_name.paginate(:page => params[:page], :per_page => @@per_page)
      @paginate     = true
    end
    
    respond_to do |format|
      format.html
      format.js
      format.json { render(:json => @customers.to_json(:only => ['id', 'name', 'email'])) }
    end
  end

  # GET /customers/1
  # def show
  #   @customer = User.find(params[:id])
  #   @note     = Note.new
  #   
  #   # build notes collection, most recent first
  #   @notes    = @customer.notes.sort_recent
  # 
  #   respond_to do |format|
  #     format.html
  #   end
  # end

end
