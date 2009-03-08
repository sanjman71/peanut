class OpeningsController < ApplicationController

  # GET /openings
  # GET /:schedulable/1/services/3/openings/this-week/morning
  # GET /services/1/openings/this-week/anytime
  def index
    if (params[:id] == "0") or (params[:schedulable_type] == "0") or (params[:schedulable_id] == "0")
      # /:schedulable/0/openings is canonicalized to /openings; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :schedulable_type => nil, :schedulable_id => nil)))
    elsif params[:service_id].to_s == "0"
      # /services/0/openings is canonicalized to /openings; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :service_id => nil)))
    end
    
    # initialize schedulable, default to anyone
    @schedulable  = current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:schedulable_id], params[:schedulable_type].to_s.classify)
    @schedulable  = User.anyone if @schedulable.blank?
    
    # initialize when, no default
    @when         = params[:when].from_url_param if params[:when]
    @daterange    = DateRange.parse_when(@when) unless @when.blank?
    
    # initialize time
    @time         = params[:time].from_url_param if params[:time]

    # initialize location & locations
    if params[:location_id]
      session[:location_id] = params[:location_id].to_i
      @current_location = @current_locations.select { |l| l.id == session[:location_id] }.first
      @current_location = Location.anywhere if @current_location.blank?
    end

    @locations = current_locations

    # initialize service, default to nothing
    @service  = current_company.services.find_by_id(params[:service_id].to_i) || Service.nothing
    
    # build appointment request for the selected timespan
    @query    = AppointmentRequest.new(:service => @service, :schedulable => @schedulable, :when => @when, :time => @time,
                                       :company => current_company, :location => current_location)

     # initialize duration
     @duration = 0
     if params[:duration_size] && params[:duration_units]
       duration_size = params[:duration_size].to_i
       duration_units = params[:duration_units]
       @duration = eval("#{params[:duration_size]}.#{params[:duration_units]}") if (duration_size && duration_units)
       # @duration holds the custom duration in seconds. We need this in minutes.
       @query.duration = @duration / 60
     end

    # build schedulables collection, schedulables are restricted by the services they perform
    @schedulables = Array(User.anyone) + @service.schedulables
    
    # find services collection, services are restricted by the company they belong to
    @services     = Array(Service.nothing(:name => "Select a service")) + current_company.services.work

    # build service providers collection mapping services to schedulables
    @sps          = current_company.services.work.inject([]) do |array, service|
      service.schedulables.each do |schedulable|
        array << [service.id, schedulable.id, schedulable.name, schedulable.tableize]
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

  def search
    # remove 'authenticity_token' params
    params.delete('authenticity_token')
    # url format parameters
    ['when', 'time'].each do |s|
      params[s] = params[s].to_url_param if params[s]
    end
    schedulable_type, schedulable_id = params.delete(:schedulable).split('/')
    redirect_to url_for(params.update(:subdomain => @subdomain, :action => 'index', :schedulable_type => schedulable_type, :schedulable_id => schedulable_id))
  end
  
end
