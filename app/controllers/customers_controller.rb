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
        @collection = build_customers_autocomplete_collection(@customers, [:name, :email, :phone])
        render(:json => @collection.to_json)
        # render(:json => @customers.to_json(:include => [:email_addresses, :phone_numbers], :only => ["id", "name", "address"]))
      end
      format.mobile
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

  def build_customers_autocomplete_collection(customers, fields=[])
    customers.inject([]) do |array, customer|
      hash = Hash[:id => customer.id]
      hash[:name]   = customer.name if fields.include?(:name)
      hash[:email]  = customer.primary_email_address.andand.address || '' if fields.include?(:email)
      hash[:phone]  = customer.primary_phone_number.andand.address || '' if fields.include?(:phone)
      array.push(hash)
      array
    end
  end

end
