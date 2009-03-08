class CompaniesController < ApplicationController
  after_filter :store_location, :only => [:index, :show, :edit]
  layout "company"

  privilege_required 'read companies', :only => [:index]
  privilege_required 'update companies', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete companies', :only => [:destroy], :on => :current_company

  # GET /companies
  # GET /companies.xml
  def index
    @companies = Company.find(:all)
    
    respond_to do |format|
      # use home layout when listing all companies
      format.html { render :action => :index, :layout => 'home' }
      format.xml  { render :xml => @companies }
    end
  end
  
  def show
    # find services collection, services are restricted by the company they belong to. Initially no service is selected
    @service  = Service.nothing
    @services     = Array(Service.nothing(:name => "Select a service")) + current_company.services.work
    
    # Set up schedulables. Initially no schedulable is selected
    @schedulable  = User.anyone
    @schedulables = Array(User.anyone) + @service.schedulables

    # Set up time
    @when = @time = nil

    # Set up locations
    @current_location = @current_locations.select { |l| l.id == session[:location_id] }.first
    @current_location = Location.anywhere if @current_location.blank?
    @locations = current_locations
    
    # Set up duration
    @duration_size = 1
    @duration_units = 'hours'
    @duration = 1.hours

    # Set up query
    @query    = AppointmentRequest.new(:service => @service, :schedulable => @schedulable, :when => @when, :time => @time, 
                                       :company => current_company, :location => current_location)

    # Set up service providers
    @sps      = current_company.services.work.inject([]) do |array, service|
      service.schedulables.each do |schedulable|
        array << [service.id, schedulable.id, schedulable.name, schedulable.tableize]
      end
      array
    end

  end

  # GET /companies/1/edit
  def edit
    if (params[:id].blank? && current_company)
      @company = current_company
    else
      @company = Company.find(params[:id])
    end
  end
  
  # PUT /companies/1
  # PUT /companies/1.xml
  def update
    @company = Company.find(params[:id])

    respond_to do |format|
      if @company.update_attributes(params[:company])
        flash[:notice] = 'Company was successfully updated.'
        # redirect to edit company page, since company show doesn't really show anything
        format.html { redirect_to(edit_company_root_path(:subdomain => @subdomain)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.xml
  def destroy
    @company.destroy

    respond_to do |format|
      format.html { redirect_to(companies_url) }
      format.xml  { head :ok }
    end
  end
  
end
