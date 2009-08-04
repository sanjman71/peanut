class CalendarController < ApplicationController
  before_filter :init_provider, :only => [:show, :edit_block, :edit_weekly]
  before_filter :init_provider_privileges, :only => [:show, :edit_block, :edit_weekly]
  
  privilege_required      'read calendars', :only => [:index, :search], :on => :current_company
  privilege_required_any  'read calendars', :only => [:show], :on => [:provider, :current_company]
  privilege_required_any  'update calendars', :only => [:edit_block, :edit_weekly], :on => [:provider, :current_company]

  # Default when value
  @@default_when = Appointment::WHEN_THIS_WEEK
  
  def index
    # redirect to a specific provider, try the current first and default to the first company provider
    provider = current_company.users.find_by_id(current_user.id) || current_company.providers.first
    if provider.blank?
      redirect_to root_path(:subdomain => current_subdomain) and return
    end
    url_params  = {:action => 'show', :provider_type => provider.tableize, :provider_id => provider.id, :subdomain => current_subdomain}
    redirect_to url_for(url_params) and return
  end
  
  # GET /users/1/calendar
  # GET /users/1/calendar/when/next-week
  # GET /users/1/calendar/range/20090101..20090201
  def show
    # @provider initialized in before_filter
    
    # if current_company.providers_count == 0
    #   # redirect to company home page
    #   redirect_to root_path(:subdomain => current_subdomain) and return
    # end
    
    @free_service = current_company.free_service
    @providers    = current_company.providers.all

    if params[:start_date] and params[:end_date]
      # build daterange using range values
      @start_date = params[:start_date]
      @end_date   = params[:end_date]
      @daterange  = DateRange.parse_range(@start_date, @end_date)
    else
      # build daterange using when
      @when       = (params[:when] || @@default_when).from_url_param
      @daterange  = DateRange.parse_when(@when, :include => :today)
    end

    # find free, work appointments for the specified provider over a daterange
    @appointments = AppointmentScheduler.find_free_work_appointments(current_company, current_location, @provider, @daterange)
        
    logger.debug("*** found #{@appointments.size} appointments over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings    = build_calendar_markings(@appointments)

    # group appointments by day
    @appointments_by_day  = @appointments.group_by { |appt| appt.start_at.beginning_of_day }

    # partition into work and free appointments
    @work_appointments, @free_appointments = @appointments.partition { |appt| appt.mark_as == Appointment::WORK }
     
    respond_to do |format|
      format.html
      format.pdf
    end
  end
  
  # GET  /calendar/search
  # POST /calendar/search
  #  - search a provider's calendar by date range => params[:start_date], params[:end_date]
  def search
    if request.post?
      # reformat start_date, end_date strings, and redirect to index action
      start_date  = sprintf("%s", params[:start_date].split('/').reverse.swap!(1,2).join)
      end_date    = sprintf("%s", params[:end_date].split('/').reverse.swap!(1,2).join)
      redirect_to url_for(:action => 'show', :start_date => start_date, :end_date => end_date, :subdomain => current_subdomain)
    end
  end
  
  # GET /users/1/calendar/block/edit
  def edit_block
    # @provider initialized in before_filter
    
    # if params[:provider_type].blank? or params[:provider_id].blank?
    #   # no provider was specified, redirect to the company's first provider
    #   provider = current_company.providers.first
    #   redirect_to url_for(params.update(:subdomain => current_subdomain, :provider_type => provider.tableize, :provider_id => provider.id)) and return
    # end
        
    # initialize provider, default to anyone
    # @provider  = User.anyone if @provider.blank?
    
    # build list of providers to allow the scheduled to be adjusted by resource
    @providers = current_company.providers.all
    
    # initialize daterange, start calendar on sunday, end calendar on sunday
    @daterange = DateRange.parse_when('next 4 weeks', :start_on => 0, :end_on => 0)
        
    # find free work appointments
    @free_work_appts    = AppointmentScheduler.find_free_work_appointments(current_company, current_location, @provider, @daterange)

    # group appointments by day
    @free_work_appts_by_day = @free_work_appts.group_by { |appt| appt.start_at.utc.beginning_of_day }
    
    # build calendar markings from free appointments
    @calendar_markings  = build_calendar_markings(@free_work_appts)
    
    # build time of day collection
    # TODO xxx - need a better way of mapping these times to start, end hours
    @tod        = ['morning', 'afternoon']
    @tod_start  = 'morning'
    @tod_end    = 'afternoon'
    
    @free_service = current_company.free_service
    
    respond_to do |format|
      format.html
    end
  end
  
  # GET /users/1/calendar/weekly/edit
  def edit_weekly
    # @provider initialize in before_filter
    
    if params[:provider_type].blank? or params[:provider_id].blank?
      # no provider was specified, redirect to the company's first provider
      provider = current_company.providers.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :provider_type => provider.tableize, :provider_id => provider.id)) and return
    end

    # build list of providers to allow the scheduled to be adjusted by resource
    @providers = current_company.providers.all

    # initialize daterange, start calendar on sunday, end calendar on sunday, dont care about 'when'
    @daterange = DateRange.parse_when('this week', :start_on => 0, :end_on => 0)

    # initialize calendar markings to empty
    @calendar_markings  = Hash.new

    respond_to do |format|
      format.html
    end
  end
  
  protected
  
  # find scheduable from the params hash
  def init_provider
    @provider = current_company.providers.find_by_provider_id_and_provider_type(params[:provider_id], params[:provider_type].to_s.classify)
  end
  
  def init_provider_privileges
    @current_privileges[@provider] = current_user.privileges(@provider).collect(&:name)
  end
end