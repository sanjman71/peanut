class LocationsController < ApplicationController
  before_filter :init_current_company
  after_filter  :store_location, :only => [:index, :show]
  
  # GET /locations
  # GET /locations.xml
  def index
    @locations = @current_company.locations.paginate :page => params[:locations_page]

    respond_to do |format|
      format.html # index.html.erb
      format.js   # index.js.rjs
    end
  end

  # GET /locations/1
  # GET /locations/1.xml
  def show
    @location = @current_company.locations.find_by_id(params[:id]) || Location.anywhere
    
    respond_to do |format|
      format.html # show.html.erb
      format.js { render :partial => 'show_location.html.erb', :object => @location }
      format.xml  { render :xml => @location.to_xml }
    end
  end
  
  # GET /locations/1/set_default
  def set_default
    @location = @current_company.locations.find_by_id(params[:id]) || Location.anywhere
    
    if request.referrer
      session[:location_id] = @location.id
      redirect_to(request.referrer) and return
    end

  end

  # GET /locations/new
  def new
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
    @location = Location.new(params[:location])
    
    # add location to current company
    @current_company.locations << @location if @current_company
    
    if @location.save
      flash[:notice] = 'Location was successfully created.'
      respond_to do |format|
        format.html { redirect_to(redirect_success_path) }
        format.xml  { head :created, :location => location_url(@location) }
      end
    else
      flash[:error] = 'Problem creating location.'
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @location.errors.to_xml }
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
  
  protected

  def redirect_success_path
    edit_company_path(@current_company, :subdomain => @subdomain)
  end
  
  # Merges conditions so that the result is a valid +condition+ 
  def merge_conditions(conditions)
    
    condition_str = ""
    args_hash = {}
    
    # Assume each condition consists of a string followed by arguments
    # We'll concatenate all the strings, and concatenate the arguments
    # where the arguments are hashes, we'll merge them.    
    conditions = conditions.find_all {|c| not c.nil? and not c.empty? }
    condition_str = conditions.collect{|c| c[0]}.join(' AND ')
    conditions.collect{|c| c[1]}.each { |c| args_hash = args_hash.merge(c) unless c.nil? }
    [condition_str, args_hash]
  end
    
end
