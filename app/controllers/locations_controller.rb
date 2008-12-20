class LocationsController < ApplicationController
  before_filter :init_current_company, :get_context
  after_filter :store_location, :only => [:index, :show]
  
  layout 'default'
  
  # GET /locations
  # GET /locations.xml
  def index

    if @current_company
      @locations = Location.locatable(@current_company).paginate :page => params[:locations_page]

      respond_to do |format|
        format.html # index.html.erb
        format.js # index.js.rjs
      end

    else
      flash[:error] = "No company specified"

      respond_to do |format|
        format.html { redirect_to root_url }
      end
    end
  end

  # GET /locations/1
  # GET /locations/1.xml
  def show
    @location = Location.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.js { render :partial => 'show_location.html.erb', :object => @location }
      format.xml  { render :xml => @location.to_xml }
    end
  end

  # GET /locations/new
  def new
    @location = Location.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.js # new.js.rjs
    end
  end

  # GET /locations/1/edit
  def edit
    @location = Location.find(params[:id])
    
    @context_url = location_url(@location) if @context_url.blank? && @location
    
    respond_to do |format|
      format.html # edit.html.erb
      format.js # edit.js.rjs
    end
    
  end

  # POST /locations
  # POST /locations.xml
  def create
    @location = Location.new(params[:location])
    @location.locatable = @current_company if @current_company
    
    @context_url = location_url(@location) if @context_url.blank?
    
    if @location.save
      flash[:notice] = 'Location was successfully created.'
      respond_to do |format|
        format.html { redirect_to @context_url }
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

    if @location
      @context_url = location_url(@location) if @context_url.blank?
    end
    
    if @location.update_attributes(params[:location])
      respond_to do |format|
        flash[:notice] = 'Location was successfully updated.'
        format.html { redirect_back_or_default('/') }
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
    
    @context_url = locations_url if @context_url.blank?
    
    if @location
      if @location.locatable
        locatable = @location.locatable
        locatable.locations.delete(@location)
      else
        @location.destroy
      end
    end
    
    respond_to do |format|
      format.html { redirect_to @context_url }
      format.xml  { head :ok }
    end
  end
  
  protected
  
  def get_context
    @context_url = case
      when @current_company then company_url(@current_company)
      else ''
    end
    # We do authorization on the parent as appropriate. 
    @may_edit_parent = has_privilege?("update company", @current_company)
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
