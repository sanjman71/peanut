class ProductsController < ApplicationController
  privilege_required 'create products', :only => [:new, :create], :on => :current_company
  privilege_required 'read products', :only => [:index, :show], :on => :current_company
  privilege_required 'update products', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete products', :only => [:destroy], :on => :current_company
  
  # GET /products
  # GET /products.xml
  def index
    @products = current_company.products.paginate(:page => params[:page], :order => "name ASC")
  end
  
  # POST /products
  # POST /products.xml
  def create
    @product = current_company.products.new(params[:product])
    
    if !@product.valid?
      @error      = true
      flash[:error] = "Could not create product"
      return
    end
    
    # save product
    @product.save
    
    # set redirect path
    @redirect_path = edit_product_path(@product)
    
    respond_to do |format|
      format.js # redirect to edit page
    end
  end
  
  # GET /products/1/edit
  def edit
    @product = current_company.products.find(params[:id])
  end
  
  # PUT /products/1
  # PUT /products/1.xml
  def update
    @product  = Product.find(params[:id])
    @status   = @product.update_attributes(params[:product])
    
    if !@status
      raise Exception, "Error updating product"
    end
    
    redirect_to(products_path)
  end

  # DELETE /products/1
  # DELETE /products/1.xml
  def destroy
    @product = current_company.products.find(params[:id])
    @product.destroy

    flash[:notice] = "Removed product #{@product.name}"

    # build products collection
    @products = current_company.products
  end
  
end