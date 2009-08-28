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
    
    respond_to do |format|
      format.html # edit.html.haml
      format.js # edit.js.rjs
    end
    
  end

  # POST /locations
  # POST /locations.xml
  def create
    if !current_company
      flash[:error] = "To add a location you must be working with a specific company."
      redirect_to root_path and return
    end
    
    if !current_company.may_add_location?
      flash[:error] = "Your plan does not allow you to add another location."
      redirect_to(edit_company_root_path(:subdomain => current_subdomain)) and return
    end
        
    @location = initialize_location(Location.new, params[:location])
    
    @location.update_attributes(params[:location]) unless !@location.errors.empty?

    if @location.errors.empty? && current_company.locations << @location
    
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

    @location = initialize_location(@location, params[:location])

    @location.update_attributes(params[:location]) unless !@location.errors.empty?

    if @location.errors.empty?
      respond_to do |format|
        flash[:notice] = 'Location was successfully updated.'
        format.html { redirect_to(redirect_success_path) }
      end
    else
      respond_to do |format|
        flash[:error] = 'Problem updating location.'
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
  
  #
  # initialize_location is set up to initialize the location in the correct order
  # This means that we want to make sure to pick the correct city id depending on the state
  # For example, if there's a Springfield, IL and Springfield, CA, we want to pick the correct one
  # depending on which state is chosen
  #
  def initialize_location(location, params)

    # Initialize the country, state, city and zip in order
    if params[:country_id]
      new_country = Country.find(params[:country_id].to_i) unless location.country_id == params[:country_id].to_i
      if new_country
        location.country = new_country
      elsif location.country_id != params[:country_id].to_i
        location.errors.add(:country, "is missing or invalid")
      end
    else
      location.errors.add(:country, "is missing or invalid")      
    end
    
    if params[:state_id]
      new_state = State.find(params[:state_id].to_i) unless location.state_id == params[:state_id].to_i
      if new_state
        location.state = new_state
      elsif location.state_id != params[:state_id].to_i
        location.errors.add(:state, "is missing or invalid")
      end
    else
      location.errors.add(:state, "is missing or invalid")
    end
    
    if !params[:city].blank? && location.state
      location.city = location.state.cities.find_or_create_by_name(params[:city])
    else
      if !location.state
        location.errors.add(:city, "can't be added without state")
      else
        location.errors.add(:city, "cannot be blank")
      end
    end
    
    if !params[:zip].blank? && location.state
      location.zip = location.state.zips.find_or_create_by_name(params[:zip])
    else
      if !location.state
        location.errors.add(:zip, "can't be added without state")
      else
        location.errors.add(:zip, "cannot be blank")
      end
    end

    # Catch a street address error if appropriate
    if params[:street_address].blank?
      location.errors.add(:street_address, "can't be blank")
    end

    # Remove these parameters - we don't want to pass them to update_attributes or create
    params.delete(:country_id)
    params.delete(:state_id)
    params.delete(:city)
    params.delete(:zip)
    
    location
  end
  
end
