class CalendarController < ApplicationController

  # Set bounce-back for the show page
  after_filter  :store_location, :only => [:show]

  before_filter :init_provider, :only => [:show2]
  before_filter :init_providers, :only => [:events, :show]
  before_filter :init_provider_privileges, :only => [:show2]

  privilege_required      'read calendars', :only => [:index], :on => :current_company
  privilege_required_any  'read calendars', :only => [:show, :show2], :on => [:provider, :current_company], :unless => :auth_token?

  # Default when value
  @@default_when = Appointment::WHEN_NEXT_2WEEKS

  def index
    if mobile_device?
      # show index page for mobile devices
      @providers  = current_company.providers
      @services   = current_company.services.with_providers.work
      # map services to providers and providers to services
      @sps, @ps   = build_service_provider_mappings(@services)

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
      redirect_to calendar_show_path(:provider_type => provider.tableize, :provider_ids => provider.id) and return
    end
  end

  # GET /users/1,2/calendar/events?start=1280638800&end=1284267600
  # GET /users/1,3/calendar/events/20102001..20100215
  def events
    # @providers, @provider initialized in before_filter

    if params[:start].match(/^201\d{5}/) and params[:end].match(/^201\d{5}/)
      # dates, e.g. 20100822, 20100822T020000
      @start_date = params[:start]
      @end_date   = params[:end]
      @daterange  = DateRange.parse_range(@start_date, @end_date, :start_week_on => current_company.preferences[:start_wday].to_i)
    else
      # unix timestamp, e.g. 1280638800, 1284267600
      @start_date = Time.zone.at(params[:start].to_i).to_s(:appt_schedule)
      @end_date   = Time.zone.at(params[:end].to_i).to_s(:appt_schedule)
      @daterange  = DateRange.parse_range(@start_date, @end_date, :start_week_on => current_company.preferences[:start_wday].to_i)
    end

    @work_appointments = []
    @free_appointments = []
    
    @providers.each do |provider|
      @work_appointments += AppointmentScheduler.find_work_appointments(current_company, current_location, provider, @daterange)
      @free_appointments += AppointmentScheduler.find_free_appointments(current_company, current_location, provider, nil, nil, @daterange, :keep_old => true)
    end

    # provider class/colors for css
    @provider_colors = Hash[]
    @providers.each_with_index do |provider, index|
      @provider_colors[provider.id] = "color#{index}"
    end

    respond_to do |format|
      format.json do
        appts = (@free_appointments + @work_appointments).inject([]) do |array, appt|
          title = appt.free? ? "#{appt.provider.name}: Available" : "#{appt.provider.name}: #{appt.service.name} : #{appt.customer.name}";
          klass = [@provider_colors[appt.provider.id]];
          klass.push('available') if  appt.free?
          array.push(Hash['title' => title,
                          'className' => klass.join(' '),
                          "appt_id" => appt.id,
                          "appt_type" => appt.class.to_s,
                          "appt_mark_as" => appt.mark_as,
                          "appt_schedule_day" => appt.start_at.to_s(:appt_schedule_day),
                          "appt_start_time" => appt.start_at.to_s(:appt_time).downcase,
                          "appt_end_time" => appt.end_at.to_s(:appt_time).downcase,
                          "appt_duration" => appt.duration,
                          "appt_provider" => "#{appt.provider_type.tableize}/#{appt.provider_id}",
                          "appt_creator" => appt.creator.try(:name).to_s,
                          "appt_service" => appt.service.try(:name).to_s,
                          "appt_service_id" => appt.service.try(:id).to_i,
                          "appt_customer" => appt.customer.try(:name).to_s,
                          "appt_customer_id" => appt.customer_id,
                          'start'   => appt.start_at.strftime("%a, %d %b %Y %H:%M:%S"),
                          'end'     => appt.end_at.strftime("%a, %d %b %Y %H:%M:%S"),
                          'allDay'  => false
                         ])
        end
        render :json => appts.to_json
      end
      format.mobile do
        # find capacity slots, combine capacity and work
        @capacity_slots             = AppointmentScheduler.find_free_capacity_slots(current_company, current_location, @provider, nil, nil, @daterange, :keep_old => true)
        @capacity_and_work          = (@capacity_slots + @work_appointments).sort_by { |o| [o.start_at.in_time_zone, ((o.class == CapacitySlot) ? 0 : 1)] }
        # group free and work appointments by day
        @free_appointments_by_day   = @free_appointments.group_by {|x| x.start_at.in_time_zone.beginning_of_day }
        @capacity_and_work_by_day   = @capacity_and_work.group_by {|x| x.start_at.in_time_zone.beginning_of_day }
        # find days with work, free activity
        @days_with_work_free_stuff  = (@free_appointments_by_day.keys + @capacity_and_work_by_day.keys).uniq.sort
      end
      format.pdf do
        # find capacity slots
        @capacity_slots           = AppointmentScheduler.find_free_capacity_slots(current_company, current_location, @provider, nil, nil, @daterange, :keep_old => true)
        # combine capacity and work, group by day
        @capacity_and_work        = (@capacity_slots + @work_appointments).sort_by { |o| [o.start_at.in_time_zone, ((o.class == CapacitySlot) ? 0 : 1)] }
        @capacity_and_work_by_day = @capacity_and_work.group_by {|x| x.start_at.in_time_zone.beginning_of_day }
      end
      format.email do
        @link     = url_for(params.merge(:format => "pdf", :address => nil, :token => AUTH_TOKEN_INSTANCE))
        @subject  = 'Your PDF Schedule'
        @email    = params[:address] ? (EmailAddress.find_by_id(params[:address].to_i) || EmailAddress.find_by_address(params[:address])) : @provider.primary_email_address
        if !@email.blank?
          @job = PdfMailerJob.new(:url => @link, :address => @email.address, :subject => @subject)
          Delayed::Job.enqueue(@job)
          flash[:notice] = "Sent PDF Schedule to #{@email.address}"
        else
          flash[:notice] = "Could not find a valid email address"
        end
        redirect_to(request.referer || calendar2_show_path(:provider_type => @provider.tableize, :provider_id => @provider.id)) and return
      end
    end
  end

  # GET /users/1/calendar2
  # GET /users/1,2/calendar2
  def show
    # @providers, @provider initialized in before_filter

    # re-initialize @provider based on number of providers
    @provider = (@providers.size == 1) ? @providers.first : User.anyone

    if params[:start] and params[:end]
      # unix timestamp e.g. 1280638800, 1284267600
      @start_date = Time.zone.at(params[:start].to_i).to_s(:appt_schedule)
      @end_date   = Time.zone.at(params[:end].to_i).to_s(:appt_schedule)
      @daterange  = DateRange.parse_range(@start_date, @end_date, :start_week_on => current_company.preferences[:start_wday].to_i)
    end

    if FULLCALENDAR_JS == 0

    @work_appointments = []
    @free_appointments = []

    @providers.each do |provider|
      @work_appointments += AppointmentScheduler.find_work_appointments(current_company, current_location, provider, @daterange)
      @free_appointments += AppointmentScheduler.find_free_appointments(current_company, current_location, provider, nil, nil, @daterange, :keep_old => true)
    end

    # provider class/colors for css
    @provider_colors = Hash[]
    @providers.each_with_index do |provider, index|
      @provider_colors[provider.id] = "color#{index}"
    end

    end # FULLCALENDAR_JS
  
    # find services collection for the current company; valid services must have at least 1 service provider
    @free_service   = current_company.free_service
    @work_services  = current_company.services.with_providers.work
    @all_providers  = current_company.providers
    @today          = DateRange.today.beginning_of_day

    # map services to providers and providers to services - used by javascript in create/edit appt dialogs
    @sps, @ps       = build_service_provider_mappings(@work_services)

    # page title
    case @providers.size
    when 1
      @title = "#{@providers.first.name.titleize} Schedule"
    else
      @title = "Provider Schedules"
    end

    respond_to do |format|
      format.html
    end
  end

  # GET /users/1/calendar?date=20100101
  # GET /users/1/calendar/when/today
  # GET /users/1/calendar/when/next-week
  # GET /users/1/calendar/when/next-2-weeks/20090201
  # GET /users/1/calendar/range/20090101..20090201
  # GET /users/1/calendar/monthly/20100101
  def show2
    # @provider initialized in before_filter

    # Remember which provider we're working with
    session[:provider_class] = @provider.class.to_s
    session[:provider_id]    = @provider.id.to_i

    # find services collection for the current company; valid services must have at least 1 service provider
    @services = current_company.services.with_providers.work

    # map services to providers and providers to services - used by javascript in create/edit appt dialogs
    @sps, @ps   = build_service_provider_mappings(@services)
    
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
      @start_date = params[:start_date] ? Time.zone.parse(params[:start_date]).in_time_zone : nil
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

    # combine capacity and work; 
    @capacity_and_work   = (@capacity_slots + @work_appointments).sort_by { |o| [o.start_at.in_time_zone, ((o.class == CapacitySlot) ? 0 : 1)] }

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
    @waitlists_by_day         = @waitlists.group_by { |waitlist, date, time_range| date }

    # find days with some type of activity
    @days_with_stuff          = (@free_appointments_by_day.keys + @capacity_and_work_by_day.keys + @waitlists_by_day.keys +
                                 @canceled_by_day.keys + @vacation_by_day.keys).uniq.sort

    # find days with work, free activity - used by mobile version
    @days_with_work_free_stuff = (@free_appointments_by_day.keys + @capacity_and_work_by_day.keys).uniq.sort

    # page title
    @title = "#{@provider.name.titleize} Schedule"

    respond_to do |format|
      format.html { render(:action => 'show_orig') }
      format.pdf
      format.email do
        @link     = url_for(params.merge(:format => "pdf", :address => nil, :token => AUTH_TOKEN_INSTANCE))
        @subject  = 'Your PDF Schedule'
        @email    = params[:address] ? (EmailAddress.find_by_id(params[:address].to_i) || EmailAddress.find_by_address(params[:address])) : @provider.primary_email_address
        if !@email.blank?
          @job = PdfMailerJob.new(:url => @link, :address => @email.address, :subject => @subject)
          Delayed::Job.enqueue(@job)
          flash[:notice] = "Sent PDF Schedule to #{@email.address}"
        else
          flash[:notice] = "Could not find a valid email address"
        end
        redirect_to(request.referer || calendar2_show_path(:provider_type => @provider.tableize, :provider_id => @provider.id)) and return
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
      redirect_to url_for(:action => 'events', :start => start_date, :end => end_date, :format => format)
    end
  end

end