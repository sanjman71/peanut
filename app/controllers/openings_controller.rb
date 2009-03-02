class OpeningsController < ApplicationController

  # GET /openings
  # GET /people/1/services/3/openings?when=this+week&time=morning
  # GET /services/1/openings?time=anytime&when=this+week
  def index
    if params[:id] == "0" or params[:resource] == "0"
      # /:resource/0/openings is canonicalized to /free; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :resource => nil, :id => nil)))
    elsif params[:service_id].to_s == "0"
      # /services/0/free is canonicalized to /free; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :service_id => nil)))
    end
    
    # initialize resource, default to anyone
    @resource   = current_company.resources.find_by_resource_id_and_resource_type(params[:id], params[:resource].to_s.classify)
    @resource   = User.anyone if @resource.blank?
    
    # initialize when, no default
    @when       = params[:when].from_url_param if params[:when]
    @daterange  = DateRange.parse_when(@when) unless @when.blank?
    
    # initialize time
    @time       = params[:time].from_url_param if params[:time]

    # initialize service, default to nothing
    @service    = current_company.services.find_by_id(params[:service_id].to_i) || Service.nothing

    # build appointment request for the selected timespan
    @query      = AppointmentRequest.new(:service => @service, :resource => @resource, :when => @when, :time => @time, :company => current_company,
                                         :location => current_location)

    # build resources collection, resources are restricted by the services they perform
    @resources  = Array(User.anyone) + @service.resources
    
    # find services collection, services are restricted by the company they belong to
    @services   = Array(Service.nothing(:name => "Select a service")) + current_company.services.work

    # build skills collection mapping services to people/resources
    @skills     = current_company.services.work.inject([]) do |array, service|
      service.resources.each do |resource|
        array << [service.id, resource.id, resource.name, resource.tableize]
      end
      array
    end

    if @when.blank?
      logger.debug("*** showing empty page with help text")
      # render empty page with help text
      return
    end

    logger.debug("*** finding free time #{@when}")
    
    # find free appointments, and free timeslots for each free apppointment
    @free_appointments  = @query.find_free_appointments
    @free_timeslots     = @free_appointments.inject([]) do |timeslots, free_appointment|
      timeslots += @query.find_free_timeslots(:appointments => free_appointment, :limit => 2)
    end
    @free_timeslots_by_day = @free_timeslots.group_by { |timeslot| timeslot.start_at.beginning_of_day }
    
    logger.debug("*** found #{@free_appointments.size} free appointments, #{@free_timeslots.size} free timeslots over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings  = build_calendar_markings(@free_timeslots)

    # build openings cache key
    @openings_cache_key = "openings:" + CacheKey.schedule(@daterange, @free_appointments, @time)
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # temporary fix to format problem
  def search
    # remove 'authenticity_token' params
    params.delete('authenticity_token')
    # url format parameters
    ['when', 'time'].each do |s|
      params[s] = params[s].to_url_param if params[s]
    end
    resource, id = params.delete(:resource_id).split('/')
    redirect_to url_for(params.update(:subdomain => @subdomain, :action => 'index', :resource => resource, :id => id))
  end
  
end
