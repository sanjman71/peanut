class ResourcesController < ApplicationController
  privilege_required 'create resources', :only => [:new, :create], :on => :current_company
  privilege_required 'update resources', :only => [:edit, :update], :on => :current_company
  
  # GET /resources/new
  def new
    if !current_company.may_add_provider?
      flash[:error] = "Your plan does not allow you to add another provider."
      redirect_to(providers_path) and return
    end
    
    @resource = Resource.new

    respond_to do |format|
      format.html
    end
  end
  
  # GET /resources/1/edit
  def edit
    @resource = current_company.resource_providers.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  # POST /resources
  def create
    @resource = Resource.new(params[:resource])
    
    if !@resource.valid?
      flash.now[:error] = "Could not create resource"
      render(:action => 'new') and return
    end
    
    # create resource and add as a company provider
    @resource.save
    current_company.resource_providers.push(@resource)
    
    # redirect to providers page
    @redirect_path = providers_path
    flash[:notice] = "Created resource #{@resource.name}"
    
    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js { render(:update) {|page| page.redirect_to(@redirect_path) } }
    end
  end
  
  # PUT /resources/1
  def update
    @resource = Resource.find(params[:id])
    @status   = @resource.update_attributes(params[:resource])
    
    if !@status
      flash[:error] = @resource.errors.full_messages
      redirect_to(edit_resource_path(@resource, :subdomain => @subdomain)) and return
    else
      flash[:notice] = "Updated resource #{@resource.name}"
      redirect_to(providers_path) and return
    end
  end
  
end