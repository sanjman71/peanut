class CustomersController < ApplicationController

  privilege_required 'read users', :only => [:index], :on => :current_company

  @@per_page  = 10
  
  # GET /customers
  def index
    @search = params[:q]
    
    if !@search.blank?
      @customers    = current_company.authorized_customers.search_by_name_email_phone(@search).order_by_name
      @search_text  = "Customers matching '#{@search}'"
      @paginate     = false
    else
      @customers    = current_company.authorized_customers.order_by_name.paginate(:page => params[:page], :per_page => @@per_page)
      @paginate     = true
    end
    
    respond_to do |format|
      format.html
      format.js
      format.json do
        # build collection using customer name, emails, and phones
        @collection = build_customers_autocomplete_collection(@customers)
        render(:json => @collection.to_json)
        # render(:json => @customers.to_json(:include => [:email_addresses, :phone_numbers], :only => ["id", "name", "address"]))
      end
      format.mobile do
        # build collection using customer name, emails, and phones
        @collection = build_customers_autocomplete_collection(@customers)
        render(:json => @collection.to_json)
      end
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

  protected

  def build_customers_autocomplete_collection(customers)
    customers.inject([]) do |array, customer|
      hash = Hash[:id => customer.id, :name => customer.name,
                  :email => customer.primary_email_address.andand.address || '',
                  :phone => customer.primary_phone_number.andand.address || '']
      array.push(hash)
      array
    end
  end

end
