class ServicesController < ApplicationController
  before_filter :disable_global_flash, :only => [:index]
  
  privilege_required 'create services', :only => [:new, :create], :on => :current_company
  privilege_required 'read services', :only => [:index, :show], :on => :current_company
  privilege_required 'update services', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete services', :only => [:destroy], :on => :current_company

  
  # GET /services
  # GET /services.xml
  def index
    @services = current_company.services.work
  end

  # GET /services/1
  # GET /services/1.xml
  def show
    @service = Service.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /services/new
  # GET /services/new.xml
  def new
    @service = Service.new
  end

  # GET /services/1/edit
  def edit
    @service              = current_company.services.find(params[:id])
    @service_providers    = @service.service_providers
    @non_providers        = current_company.providers.all - @service.providers

    respond_to do |format|
      format.html
    end
  end

  # POST /services
  # POST /services.xml
  def create
    @service = current_company.services.new(params[:service])
    
    if !@service.valid?
      @error      = true
      @error_text = "Could not create service"
      return
    end
    
    # create service and add as a company service
    @service.save
    current_company.services.push(@service)
    
    # redirect to edit page
    @redirect_path = edit_service_path(@service)
    
    respond_to do |format|
      format.js { render(:update) {|page| page.redirect_to(@redirect_path) } }
    end
  end

  # PUT /services/1
  # PUT /services/1.xml
  def update
    @service  = Service.find(params[:id])
    @status   = @service.update_attributes(params[:service])
    
    if !@status
      flash[:error] = @service.errors.full_messages
      redirect_to(edit_service_path(@service, :subdomain => @subdomain)) and return
    else
      flash[:notice] = "Updated service #{@service.name}"
    end
    
    redirect_to(services_path)
  end

  # DELETE /services/1
  # DELETE /services/1.xml
  def destroy
    @service = current_company.services.find(params[:id])
    @service.destroy

    flash[:notice] = "Removed service #{@service.name}"
    
    # redirect to services index
    respond_to do |format|
      format.js { render(:update) {|page| page.redirect_to(services_path) } }
    end
  end
end
