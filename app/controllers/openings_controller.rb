class OpeningsController < ApplicationController
  before_filter :login_for_mobile_site, :only => [:index]
  before_filter :current_user_should_be_active_state, :only => [:index]
  after_filter  :store_location, :only => [:index]

  # Handle RecordNotFound exceptions with a redirect
  rescue_from(ActiveRecord::RecordNotFound)  { |e| redirect_to(openings_path) and return }

  # GET /ping
  def ping
    head(:ok)
  end

  # GET /openings
  # GET /users/1/services/3/3600/openings/this-week/morning
  # GET /services/1/3600/openings/this-week/anytime
  # GET /services/1/3600/openings/20100101/anytime
  def index
    if (params[:provider_type] == "0") or (params[:provider_id] == "0")
      # /:provider/0/openings is canonicalized to /openings; preserve subdomain on redirect
      redirect_to(url_for(params.update(:subdomain => current_subdomain, :provider_type => nil, :provider_id => nil))) and return
    elsif params[:service_id].to_s == "0"
      # /services/0/openings is canonicalized to /openings; preserve subdomain on redirect
      redirect_to(url_for(params.update(:subdomain => current_subdomain, :service_id => nil))) and return
    end
    
    # check public/private company preference
    @public = current_company.preferences[:public].to_i

    # check if openings are searchable
    case
    when (@public == 1) || (logged_in?)
      @searchable = true
    else
      @searchable = false
    end

    unless @searchable
      logger.debug("openings are not searchable")
      return
    end

    # check that the company has at least 1 provider and 1 work service
    if current_company.providers_count == 0 or current_company.work_services_count == 0
      redirect_to(setup_company_path(current_company)) and return
    end

    # find services collection for the current company; valid services must have at least 1 service provider
    @services = current_company.services.with_providers.work

    if @services.empty?
      # there are no services with any service providers
      redirect_to(setup_company_path(current_company)) and return
    end

    # initialize provider from params
    @provider = init_provider(:default => User.anyone)

    if params[:start_date] and params[:end_date]
      # build daterange using range values
      @start_date = params[:start_date]
      @end_date   = params[:end_date]
      @daterange  = DateRange.parse_range(@start_date, @end_date)
    elsif params[:start_date]
      # build daterange using range values
      @start_date = params[:start_date]
      @end_date   = params[:start_date]
      @daterange  = DateRange.parse_range(@start_date, @end_date)
    elsif params[:when]
      # build daterange using when value, don't use a default
      @when       = params[:when].from_url_param
      @daterange  = DateRange.parse_when(@when, :include => :today, :start_week_on => current_company.preferences[:start_wday].to_i)
    end

    # initialize time objects
    @time         = params[:time].from_url_param if params[:time]
    @time_range   = params[:time].blank? ? nil : TimeRange.new(:when => params[:time].from_url_param) # xxx no when parameter?

    # initialize today
    @today        = DateRange.today.beginning_of_day

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
    @sps = @services.inject([]) do |array, service|
      service.providers.each do |provider|
        array << [service.id, provider.id, provider.name, provider.tableize, (service.allow_custom_duration ? 1 : 0), service.duration]
      end
      array
    end

    # add the 'nothing' service to the services collection
    @services = Array(Service.nothing(:name => "Select a service")) + @services

    if mobile_device?
      # map services to providers and providers to services
      @sps, @ps = build_service_provider_mappings(@services)
      # build search when daterange, starting with tomorrow for 2 weeks
      @when = DateRange.parse_when('next 2 weeks', :start_date => (Time.zone.now+1.day))
    end

    if @daterange.blank?
      # render empty page with help text
      logger.debug("*** showing empty page with help text")
      return
    end

    # find free appointments, group by day using appt start_at in the local time zone
    @free_capacity_slots        = AppointmentScheduler.find_free_capacity_slots(current_company, current_location,
                                                                                @provider, @service, @duration, @daterange)
    @free_capacity_slots_by_day = @free_capacity_slots.group_by { |appt| appt.start_at.in_time_zone.beginning_of_day }

    logger.debug("*** found #{@free_capacity_slots.size} free capacity slots over #{@daterange.days} days")
    
    if mobile_device?
      # index capacity slots by provider
      @free_capacity_slot_by_providers = @free_capacity_slots.group_by { |slot| slot.provider }.each_with_object(Hash[]) do |tuple, hash|
        # tuple[0] is the provider, tuple[1] is a capacity slot array
        hash[tuple[0]] = tuple[1]
        hash
      end
    end

    # build hash of calendar markings
    # @calendar_markings  = build_calendar_markings_from_slots(@free_capacity_slots)

    # use an empty calendar markings hash, and mark the calendar using the free_capacity_slots_by_day hash using javascript
    @calendar_markings  = Hash[]

    # initialize customer
    @customer = current_user || nil

    # show waitlist link if the user is logged in
    if @customer
      # build waitlist object, and a child time range object
      @waitlist = Waitlist.new(:provider => @provider, :service => @service, :customer => current_user || nil)
      @waitlist.waitlist_time_ranges.build
    end

    # build openings cache key
    # @openings_cache_key = "openings:" + CacheKey.slot_schedule(@daterange, @free_capacity_slots, @time)

    # check for bookit parameter
    @bookit = params[:bookit]

    respond_to do |format|
      format.html # index.html.erb
      format.mobile
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
    
    # check time parameter
    if params[:time].blank?
      # use default time
      params[:time] = 'anytime'
    end

    # check provider parameter
    provider = params.delete(:provider)
    case
    when provider.blank? || (provider == "0")
      # any provider
      provider_type = provider_id = nil
    else
      # get provider object
      provider_type, provider_id = provider.split('/')
    end

    # build redirect path, set format to nil explicity in case its a mobile request where format is set to 'mobile'
    @redirect_path = url_for(params.merge(:action => 'index', :provider_type => provider_type, :provider_id => provider_id, :format => nil))

    respond_to do |format|
      format.html  { redirect_to(@redirect_path) }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
      format.mobile  { render(:json => Hash[:redirect => @redirect_path].to_json) }
    end
  end
  
end
