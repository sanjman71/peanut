class CalendarController < ApplicationController

  # Set bounce-back for the show page
  after_filter :store_location, :only => [:show]

  before_filter :init_provider, :only => [:show]
  before_filter :init_provider_privileges, :only => [:show]
  
  privilege_required      'read calendars', :only => [:index, :search], :on => :current_company
  privilege_required_any  'read calendars', :only => [:show], :on => [:provider, :current_company]

  # Default when value
  @@default_when = Appointment::WHEN_NEXT_2WEEKS
  
  def index
    # redirect to a specific provider. Try the most recently used, then current user, then first company provider
    if session[:provider_class] == 'Resource'
      provider = current_company.resource_providers.find_by_id(session[:provider_id].to_i) ||
                 current_company.user_providers.find_by_id(current_user.id) || 
                 current_company.providers.first
    else
      provider = current_company.user_providers.find_by_id(session[:provider_id].to_i) ||
                 current_company.user_providers.find_by_id(current_user.id) || 
                 current_company.providers.first
    end

    if provider.blank?
      redirect_to root_path(:subdomain => current_subdomain) and return
    end
    url_params  = {:action => 'show', :provider_type => provider.tableize, :provider_id => provider.id, :subdomain => current_subdomain}
    redirect_to url_for(url_params) and return
  end
  
  # GET /users/1/calendar
  # GET /users/1/calendar/when/today
  # GET /users/1/calendar/when/next-week
  # GET /users/1/calendar/when/next-2-weeks/20090201
  # GET /users/1/calendar/range/20090101..20090201
  # GET /users/1/calendar/monthly/20100101
  def show
    # @provider initialized in before_filter

    # Remember which provider we're working with
    session[:provider_class] = @provider.class.to_s
    session[:provider_id]    = @provider.id.to_i
    
    # if current_company.providers_count == 0
    #   # redirect to company home page
    #   redirect_to root_path(:subdomain => current_subdomain) and return
    # end

    @free_service = current_company.free_service
    @providers    = current_company.providers
    
    # find services collection for the current company & provider; valid services must have at least 1 service provider
    # Note: we need to explicity convert to an array because there is a naming conflict with NamedScope here
    @services = Array(current_company.services.with_provider(@provider.id))

    if params[:start_date] and params[:end_date]
      # build daterange using range values
      @start_date = params[:start_date]
      @end_date   = params[:end_date]
      @daterange  = DateRange.parse_range(@start_date, @end_date, :start_week_on => current_company.preferences[:start_wday].to_i)
    elsif params[:start_date] and params[:range_type]
      @start_date = params[:start_date]
      @daterange  = DateRange.parse_range_type(@start_date, params[:range_type])
    else
      # build daterange using when
      @when       = (params[:when] || @@default_when).from_url_param
      @start_date = params[:start_date] ? Time.parse(params[:start_date]).in_time_zone : nil
      @daterange  = DateRange.parse_when(@when, :include => :today, :start_date => @start_date, :start_week_on => current_company.preferences[:start_wday].to_i)
    end

    # find free, work appointments for the specified provider over a daterange
    # For free appointments, we don't care about service or duration, so these are set to nil
    @free_appointments   = AppointmentScheduler.find_free_appointments(current_company, current_location, @provider, nil, nil, @daterange, :keep_old => true)
    @work_appointments   = AppointmentScheduler.find_work_appointments(current_company, current_location, @provider, @daterange, :keep_old => true)
    @orphan_appointments = AppointmentScheduler.find_orphan_work_appointments(current_company, current_location, @provider, @daterange, :keep_old => true)


    # find capacity for the specified provider over the daterange. We don't care about service or duration, so these are set to nil
    @capacity            = AppointmentScheduler.find_free_capacity_slots(current_company, current_location, @provider, nil, nil, @daterange, :keep_old => true)
    @capacity            = @capacity.group_by { |x| x.free_appointment_id }
    @capacity            = @capacity.each_with_object({}) {|(k, v), h| h[k] = CapacitySlot.build_capacities_for_view(v) }
    @capacity            = @capacity.values.flatten

    # build hash of calendar markings based on the free appointments
    # @calendar_markings   = build_calendar_markings(@free_appointments)
    # logger.debug("*** calendar markings: #{@calendar_markings.inspect}")

    # use an empty calendar markings hash, and mark the calendar using the free_capacity_slots_by_day hash using javascript
    @calendar_markings   = Hash[]

    # initialize today
    @today               = DateRange.today.beginning_of_day

    # combine capacity and work, sorted by start_at time
    @capacity_and_work   = (@capacity + @work_appointments).sort_by { |x| x.start_at.in_time_zone }

    # group capacity and work by free appointments
    @capacity_and_work_by_free_appt = @capacity_and_work.group_by {|x| x.free_appointment_id }
    
    # find waitlist appointments for the specified provider over a daterange
    @waitlists = Waitlist.find_matching(current_company, current_location, @provider, @daterange).inject([]) do |array, waitlist|
      tuple = waitlist.expand_days(:start_day => @daterange.start_at, :end_day => @daterange.end_at)
      array + tuple
    end

    # group free and work appointments by day
    @free_appointments_by_day   = @free_appointments.group_by {|x| x.start_at.in_time_zone.beginning_of_day }
    @orphan_appointments_by_day = @orphan_appointments.group_by {|x| x.start_at.in_time_zone.beginning_of_day }

    # group waitlists by day
    @waitlists_by_day = @waitlists.group_by { |waitlist, date, time_range| date }

    # group appointments and waitlists by day, appointments before waitlists for any given day
    @day_keys         = (@free_appointments_by_day.keys + @waitlists_by_day.keys + @orphan_appointments_by_day.keys).uniq.sort
    @stuff_by_day     = ActiveSupport::OrderedHash[]
    @day_keys.each do |date|
      @stuff_by_day[date] = (@free_appointments_by_day[date] || []) + (@waitlists_by_day[date] || []) + (@orphan_appointments_by_day[date] || [])
    end

    # page title
    @title = "#{@provider.name.titleize} Schedule"

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
      format      = params[:format]
      redirect_to url_for(:action => 'show', :start_date => start_date, :end_date => end_date, :format => format)
    end
  end

end