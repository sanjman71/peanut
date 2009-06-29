class LocationsController < ApplicationController
  
  # GET /locations
  # GET /locations.xml
  def index
    @locations = current_company.locations.paginate :page => params[:locations_page]

    respond_to do |format|
      format.html # index.html.erb
      format.js   # index.js.rjs
    end
  end

  # GET /locations/1
  # GET /locations/1.xml
  def show
    @location = current_company.locations.find_by_id(params[:id]) || Location.anywhere
    
    respond_to do |format|
      format.html # show.html.erb
      format.js { render :partial => 'show_location.html.erb', :object => @location }
      format.xml  { render :xml => @location.to_xml }
    end
  end
  
  # GET /locations/1/select
  def select
    @location = current_company.locations.find_by_id(params[:id]) || Location.anywhere

    # cache location as a session param
    session[:location_id] = @location.id
    
    if request.referrer
      redirect_to(request.referrer) and return
    else
      redirect_to("/") and return
    end
  end

  # GET /locations/new
  def new
    
    if !current_company
      flash[:error] = "To add a location you must be working with a specific company."
      redirect_to root_path and return
    end
    
    if !current_company.may_add_location?
      flash[:error] = "Your plan does not allow you to add another location."
      redirect_to(edit_company_root_path(:subdomain => current_subdomain)) and return
    end
    
    @location = Location.new
  
    respond_to do |format|
      format.html # new.html.haml
      format.js # new.js.rjs
    end
  
  end

  # GET /locations/1/edit
  def edit
    @location = Location.find(params[:id])
    @location.city_str = @location.city.name
    @location.state_str = @location.state.code
    @location.zip_str = @location.zip.name
    @location.country_str = @location.country.code
    
    respond_to do |format|
      format.html # edit.html.haml
      format.js # edit.js.rjs
    end
    
  end

  # POST /locations
  # POST /locations.xml
  def create
    
    breakpoint
    
    if !current_company
      flash[:error] = "To add a location you must be working with a specific company."
      redirect_to root_path and return
    end
    
    if !current_company.may_add_location?
      flash[:error] = "Your plan does not allow you to add another location."
      redirect_to(edit_company_root_path(:subdomain => current_subdomain)) and return
    end
    
    @location = Location.new(params[:location])

    if current_company.locations << @location 
    
      flash[:notice] = "Location was successfully added to #{current_company.name}"

      respond_to do |format|
        format.html { redirect_to(redirect_success_path) }
      end
    else
      flash[:error] = "Problem adding location to #{current_company.name}."

      respond_to do |format|
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /locations/1
  # PUT /locations/1.xml
  def update
    @location = Location.find(params[:id])

    if @location.update_attributes(params[:location])
      respond_to do |format|
        flash[:notice] = 'Location was successfully updated.'
        format.html { redirect_to(redirect_success_path) }
      end
    else
      respond_to do |format|
        flash[:notice] = 'Problem updating location.'
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /locations/1
  # DELETE /locations/1.xml
  def destroy
    @location = Location.find(params[:id])
    
    if @location
      @location.destroy
      flash[:notice] = 'Location was successfully removed.'
    end
    
    respond_to do |format|
      format.html { redirect_to(redirect_success_path) }
      format.xml  { head :ok }
    end
  end
  
  def pick_location
    
  end
  
  protected

  def redirect_success_path
    edit_company_root_path(:subdomain => current_subdomain)
  end
  
end
