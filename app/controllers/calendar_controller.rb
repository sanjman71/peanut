class CalendarController < ApplicationController

  # Set bounce-back for the show page
  after_filter :store_location, :only => [:show]

  before_filter :init_provider, :only => [:show]
  before_filter :init_provider_privileges, :only => [:show]

  privilege_required      'read calendars', :only => [:index, :search], :on => :current_company
  privilege_required_any  'read calendars', :only => [:show], :on => [:provider, :current_company], :unless => :auth_token?

  # Default when value
  @@default_when = Appointment::WHEN_NEXT_2WEEKS

  def index
    if mobile_device?
      # show index page for mobile devices
      @providers  = current_company.providers
      @services   = Array(current_company.services.with_providers.work)
      @daterange  = DateRange.parse_when('next 7 days', :include => :today)
      @today      = DateRange.today.beginning_of_day
      render(:action => :index) and return
    else
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
  end
  
  # GET /users/1/calendar?date=20100101
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

    # find services collection for the current company; valid services must have at least 1 service provider
    # Note: we need to explicity convert to an array because there is a naming conflict with NamedScope here
    @services = Array(current_company.services.with_providers.work)

    # build service providers collection mapping services to providers
    # This is used for the javascript in some of the appointment create/edit dialogs - same as in openings controller
    @sps = @services.inject([]) do |array, service|
      service.providers.each do |provider|
        array << [service.id, provider.id, provider.name, provider.tableize, (service.allow_custom_duration ? 1 : 0), service.duration]
      end
      array
    end
    
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

    # initialize calendar date we are supposed to highlight
    @calendar_highlight_date = params[:highlight] ? params[:highlight].to_s : "first-activity"

    # find free, work appointments & capacity for the specified provider over a daterange
    # For free appointments, we don't care about service or duration, so these are set to nil
    # For capacity_slots we don't care about service, duration or capacity, so these are set to nil
    @free_appointments     = AppointmentScheduler.find_free_appointments(current_company, current_location, @provider, nil, nil, @daterange, :keep_old => true)
    @work_appointments     = AppointmentScheduler.find_work_appointments(current_company, current_location, @provider, @daterange)
    @capacity_slots        = AppointmentScheduler.find_free_capacity_slots(current_company, current_location, @provider, nil, nil, @daterange, :keep_old => true)
    @canceled_appointments = AppointmentScheduler.find_canceled_work_appointments(current_company, current_location, @provider, @daterange)
    @vacation_appointments = AppointmentScheduler.find_vacation_appointments(current_company, current_location, @provider, @daterange)

    # build hash of calendar markings based on the free appointments
    # @calendar_markings   = build_calendar_markings(@free_appointments)
    # logger.debug("*** calendar markings: #{@calendar_markings.inspect}")

    # use an empty calendar markings hash, and mark the calendar using the free_capacity_slots_by_day hash using javascript
    @calendar_markings   = Hash[]

    # initialize today
    @today               = DateRange.today.beginning_of_day

    # combine capacity and work; sorting time slots is done in the view
    @capacity_and_work   = (@capacity_slots + @work_appointments).sort_by(&:start_at)

    # find waitlist appointments for the specified provider over a daterange
    @waitlists = Waitlist.find_matching(current_company, current_location, @provider, @daterange).inject([]) do |array, waitlist|
      tuple = waitlist.expand_days(:start_day => @daterange.start_at, :end_day => @daterange.end_at)
      array + tuple
    end

    # group free and work appointments by day
    @free_appointments_by_day = @free_appointments.group_by {|x| x.start_at.in_time_zone.beginning_of_day }
    @capacity_and_work_by_day = @capacity_and_work.group_by {|x| x.start_at.in_time_zone.beginning_of_day }
    # group canceled appointments by day
    @canceled_by_day          = @canceled_appointments.group_by {|x| x.start_at.in_time_zone.beginning_of_day }
    # group vacation appointments by day
    @vacation_by_day          = @vacation_appointments.group_by {|x| x.start_at.in_time_zone.beginning_of_day }

    # group waitlists by day
    @waitlists_by_day = @waitlists.group_by { |waitlist, date, time_range| date }

    # group appointments and waitlists by day, appointments before waitlists for any given day
    @day_keys         = (@free_appointments_by_day.keys + @capacity_and_work_by_day.keys + @waitlists_by_day.keys +
                         @canceled_by_day.keys + @vacation_by_day.keys).uniq.sort
    @stuff_by_day     = ActiveSupport::OrderedHash[]
    @day_keys.each do |date|
      @stuff_by_day[date] = (@capacity_and_work_by_day[date].andand.sort_by(&:start_at) || []) +
                            (@free_appointments_by_day[date].andand.sort_by(&:start_at) || []) +              
                            (@waitlists_by_day[date].andand.sort_by(&:start_at) || []) + 
                            (@canceled_by_day[date].andand.sort_by(&:start_at) || []) +
                            (@vacation_by_day[date].andand.sort_by(&:start_at) || [])
    end

    # page title
    @title = "#{@provider.name.titleize} Schedule"

    respond_to do |format|
      format.html
      format.pdf
      format.email do
        @link     = url_for(params.merge(:format => "pdf", :address => nil))
        @subject  = 'Your PDF Schedule'
        @email    = EmailAddress.find_by_id(params[:address].to_i) || @provider.primary_email_address
        if !@email.blank?
          @job = PdfMailerJob.new(:url => @link, :address => @email.address, :subject => @subject)
          Delayed::Job.enqueue(@job)
          flash[:notice] = "Sent PDF Schedule to #{@email.address}"
        else
          flash[:notice] = "Could not find a valid email address"
        end
        redirect_to(request.referer || calendar_show_path(:provider_type => @provider.tableize, :provider_id => @provider.id)) and return
      end
      format.mobile
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