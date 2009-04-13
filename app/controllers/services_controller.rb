class ServicesController < ApplicationController
  
  privilege_required 'create services', :only => [:new, :create], :on => :current_company
  privilege_required 'read services', :only => [:index, :show], :on => :current_company
  privilege_required 'update services', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete services', :only => [:destroy], :on => :current_company

  
  # GET /services
  def index
    # only show work services
    @services = current_company.services.work

    respond_to do |format|
      format.html
    end
  end

  # GET /services/1
  # GET /services/1.xml
  def show
    @service = current_company.services.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # GET /services/new
  def new
    @service = Service.new

    respond_to do |format|
      format.html
    end
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
      render(:action => 'new') and return
    end
    
    # create service and add as a company service
    @service.save
    current_company.services.push(@service)
    
    # redirect to edit page
    @redirect_path = edit_service_path(@service, :subdomain => current_subdomain)

    flash[:notice] = "Created service #{@service.name}"
    
    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js { render(:update) {|page| page.redirect_to(@redirect_path) } }
    end
  end

  # PUT /services/1
  # PUT /services/1.xml
  def update
    @service  = Service.find(params[:id])
    @status   = @service.update_attributes(params[:service])
    
    if !@status
      flash[:error] = @service.errors.full_messages.split("\n")
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
