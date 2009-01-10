class ProductsController < ApplicationController
  before_filter :init_current_company
  
  # GET /products
  # GET /products.xml
  def index
    @products = @current_company.products
  end
  
  # POST /products
  # POST /products.xml
  def create
    @product = @current_company.products.new(params[:product])
    
    if !@product.valid?
      @error      = true
      @error_text = "Could not create producgt"
      return
    end
    
    @product.save
    
    respond_to do |format|
      format.js # redirect to edit page
    end
  end
  
  # GET /products/1/edit
  def edit
    @product = @current_company.products.find(params[:id])
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
    @product = @current_company.products.find(params[:id])
    @product.destroy

    @notice_text = "Removed product #{@product.name}"

    # build products collection
    @products = @current_company.products
  end
  
end