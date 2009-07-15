class OpeningsController < ApplicationController
  
  # Handle RecordNotFound exceptions with a redirect
  rescue_from(ActiveRecord::RecordNotFound)  { |e| redirect_to(openings_path) and return }
    
  # GET /openings
  # GET /users/1/services/3/openings/this-week/morning
  # GET /services/1/openings/this-week/anytime
  def index
    if (params[:provider_type] == "0") or (params[:provider_id] == "0")
      # /:provider/0/openings is canonicalized to /openings; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :provider_type => nil, :provider_id => nil)))
    elsif params[:service_id].to_s == "0"
      # /services/0/openings is canonicalized to /openings; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :service_id => nil)))
    end
    
    # check that the company has at least 1 provider and 1 work service
    if current_company.providers_count == 0 or current_company.work_services_count == 0
      redirect_to(setup_company_path(current_company)) and return
    end
    
    # find services collection for the current company; valid services must have at least 1 service provider
    # Note: we need to explicity convert to an array because there is a naming conflict with NamedScope here
    @services     = Array(current_company.services.with_providers.work)
    
    if @services.empty?
      # there are no services with any service providers
      redirect_to(setup_company_path(current_company)) and return
    end
    
    # initialize provider, default to anyone
    @provider  = current_company.providers.find_by_provider_id_and_provider_type(params[:provider_id], params[:provider_type].to_s.classify)
    @provider  = User.anyone if @provider.blank?
    
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
    
    # build providers collection, which are restricted by the services they perform
    @providers = @service.providers
    
    # build service providers collection mapping services to providers
    @sps          = @services.inject([]) do |array, service|
      service.providers.each do |provider|
        array << [service.id, provider.id, provider.name, provider.tableize, (service.allow_custom_duration ? 1 : 0), service.duration]
      end
      array
    end
    
    # add the 'nothing' service to the services collection
    @services     = Array(Service.nothing(:name => "Select a service")) + @services

    if @daterange.blank?
      # reset reschedule id based on params
      reset_reschedule_id_from_params
      # render empty page with help text
      logger.debug("*** showing empty page with help text")
      return
    end

    # find free appointments, group by day (use appt utc time)
    @free_appointments        = AppointmentScheduler.find_free_appointments(current_company, current_location, 
                                                                            @provider, @service, @duration, @daterange, :time => @time)
    @free_appointments_by_day = @free_appointments.group_by { |appt| appt.start_at.utc.beginning_of_day}
    
    logger.debug("*** found #{@free_appointments.size} free appointments over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings  = build_calendar_markings(@free_appointments)

    # build waitlist path
    @waitlist_path      = waitlist_path(:provider_type => @provider.tableize, :provider_id => @provider.id, :service_id => @service.id, 
                                        :start_date => @daterange.to_url_param(:for => :start_date), :end_date => @daterange.to_url_param(:for => :end_date),
                                        :subdomain => current_subdomain)
    # build openings cache key
    @openings_cache_key = "openings:" + CacheKey.schedule(@daterange, @free_appointments, @time)
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def search
    # delete the authenticity token parameter so its not passed on
    params.delete("authenticity_token")
    
    # url format 'when' parameters parameters
    ['when', 'time'].each do |s|
      params[s] = params[s].to_url_param if params[s]
    end
    
    # parse date parameters
    ['start_date', 'end_date'].each do |s|
      params[s] = sprintf("%s", params[s].split('/').reverse.swap!(1,2).join) if params[s]
    end
    
    # get provider object
    provider_type, provider_id = params.delete(:provider).split('/')
    
    # build redirect path
    @redirect_path = url_for(params.update(:subdomain => current_subdomain, :action => 'index', :provider_type => provider_type, :provider_id => provider_id))

    respond_to do |format|
      format.html  { redirect_to(@redirect_path) }
      format.js
    end
  end
  
end
