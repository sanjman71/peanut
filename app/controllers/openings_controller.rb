class OpeningsController < ApplicationController

  # Handle RecordNotFound exceptions with a redirect
  rescue_from(ActiveRecord::RecordNotFound)  { |e| redirect_to(openings_path) and return }
    
  # GET /openings
  # GET /users/1/services/3/openings/this-week/morning
  # GET /services/1/openings/this-week/anytime
  def index
    if (params[:schedulable_type] == "0") or (params[:schedulable_id] == "0")
      # /:schedulable/0/openings is canonicalized to /openings; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :schedulable_type => nil, :schedulable_id => nil)))
    elsif params[:service_id].to_s == "0"
      # /services/0/openings is canonicalized to /openings; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :service_id => nil)))
    end
    
    # initialize schedulable, default to anyone
    @schedulable  = current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:schedulable_id], params[:schedulable_type].to_s.classify)
    @schedulable  = User.anyone if @schedulable.blank?
    
    if params[:start_date] and params[:end_date]
      # build daterange using range values
      @start_date = params[:start_date]
      @end_date   = params[:end_date]
      @daterange  = DateRange.parse_range(@start_date, @end_date)
    elsif params[:when]
      # build daterange using when value, don't use a default
      @when       = params[:when].from_url_param 
      @daterange  = DateRange.parse_when(@when)
    end
    
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
    @service  = params[:service_id] ? current_company.services.find(params[:service_id].to_i) : Service.nothing
    
    # initialize duration
    @duration = params[:duration] ? params[:duration].to_i : @service.duration
    
    # if the service allows a custom duration, then set the service duration; otherwise use the default service duration
    if @service.allow_custom_duration
      @service.duration = @duration
    end

    # make sure the service duration matches the specified duration
    if @service.duration != @duration
      # redirect using the default service duration
      redirect_to(url_for(params.update(:duration => @service.duration, :subdomain => current_subdomain))) and return
    end
    
    # build schedulables collection, schedulables are restricted by the services they perform
    @schedulables = @service.schedulables
    
    # find services collection, services are restricted by the company they belong to
    @services     = Array(Service.nothing(:name => "Select a service")) + current_company.services.work

    # build service providers collection mapping services to schedulables
    @sps          = current_company.services.work.inject([]) do |array, service|
      service.schedulables.each do |schedulable|
        array << [service.id, schedulable.id, schedulable.name, schedulable.tableize, (service.allow_custom_duration ? 1 : 0), service.duration]
      end
      array
    end
    
    if @daterange.blank?
      logger.debug("*** showing empty page with help text")
      # render empty page with help text
      return
    end

    # find free appointments, group by day (use appt utc time)
    @free_appointments        = AppointmentScheduler.find_free_appointments(current_company, current_location, 
                                                                            @schedulable, @service, @duration, @daterange, :time => @time)
    @free_appointments_by_day = @free_appointments.group_by { |appt| appt.start_at.utc.beginning_of_day}
    
    logger.debug("*** found #{@free_appointments.size} free appointments over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings  = build_calendar_markings(@free_appointments)

    # flag to show waitlist link
    @show_waitlist      = @free_appointments.blank?
    
    # build openings cache key
    @openings_cache_key = "openings:" + CacheKey.schedule(@daterange, @free_appointments, @time)
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def search
    # remove 'authenticity_token' params
    params.delete('authenticity_token')
    
    # url format 'when' parameters parameters
    ['when', 'time'].each do |s|
      params[s] = params[s].to_url_param if params[s]
    end
    
    # parse date parameters
    ['start_date', 'end_date'].each do |s|
      params[s] = sprintf("%s", params[s].split('/').reverse.swap!(1,2).join) if params[s]
    end
    
    # get schedulable object
    schedulable_type, schedulable_id = params.delete(:schedulable).split('/')
    
    # build redirect path
    @redirect_path = url_for(params.update(:subdomain => current_subdomain, :action => 'index', :schedulable_type => schedulable_type, :schedulable_id => schedulable_id))

    respond_to do |format|
      format.html  { redirect_to(@redirect_path) }
      format.js
    end
  end
  
end
