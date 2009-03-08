class ServicesController < ApplicationController
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
    @service        = current_company.services.find(params[:id])
    @service_providers   = @service.service_providers
    @non_providers  = current_company.schedulables.all - @service.schedulables
  end

  # COMPONENT - GET /services/1/providers
  # show all service providers
  def providers
    @service        = current_company.services.find(params[:id])
    @service_providers = @service.service_providers
    @non_providers  = current_company.schedulables.all - @service.schedulables
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
    
    @service.save
    
    respond_to do |format|
      format.js # redirect to edit page
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
    end
    
    redirect_to(services_path)
  end

  # DELETE /services/1
  # DELETE /services/1.xml
  def destroy
    @service = current_company.services.find(params[:id])
    @service.destroy

    @notice_text = "Removed service #{@service.name}"

    # build services collection
    @services = current_company.services.work
  end
end
