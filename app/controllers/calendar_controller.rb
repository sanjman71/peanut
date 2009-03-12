class CalendarController < ApplicationController
  before_filter :disable_global_flash
  
  # Default when value
  @@default_when = Appointment::WHEN_THIS_WEEK
  
  def index
    # redirect to a specific schedulable
    schedulable = current_company.schedulables.first
    url_params  = {:action => 'show', :schedulable_type => schedulable.tableize, :schedulable_id => schedulable.id, :subdomain => current_subdomain}
    redirect_to url_for(url_params) and return
  end
  
  # GET /schedulable/1/calendar
  # GET /schedulable/1/calendar/when/next-week
  # GET /schedulable/1/calendar/range/20090101..20090201
  def show
    if params[:customer_id]
      @customer     = current_company.users.find(params[:customer_id])
      @appointments = @customer.appointments
      raise Exception, "todo: show customer appointments: #{@appointments.size}"
    end
    
    @free_service = current_company.free_service

    if current_company.schedulables_count == 0
      # show message that schedulables need to be added before viewing schedules
      return
    end
    
    # initialize resource, default to anyone
    @schedulable  = current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:schedulable_id], params[:schedulable_type].to_s.classify)
    @schedulables = current_company.schedulables.all

    if params[:start_date] and params[:end_date]
      # build daterange using range values
      @start_date = params[:start_date]
      @end_date   = params[:end_date]
      @daterange  = DateRange.parse_range(@start_date, @end_date)
    else
      # build daterange using when
      @when       = (params[:when] || @@default_when).from_url_param
      @daterange  = DateRange.parse_when(@when)
    end

    # find free, work appointments for a resource
    @appointments = AppointmentScheduler.find_free_work_appointments(current_company, current_location, @schedulable, @daterange)
        
    logger.debug("*** found #{@appointments.size} appointments over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings = build_calendar_markings(@appointments)

    logger.debug("*** calendar markings: #{@calendar_markings}")
    
    # group appointments by day
    @appointments_by_day = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
    
    respond_to do |format|
      format.html
      format.pdf do
        # create pdf and stream it to the caller
        pdf = Reports::CalendarController.render_pdf(:appointments => @appointments, :title => "Calendar Title")
        send_data pdf, :type => "application/pdf"
      end
    end
  end
  
  # GET  /appointments/search
  # POST /appointments/search
  #  - search for a schedulable's calendar by date range => params[:start_date], params[:end_date]
  def search
    if request.post?
      # reformat start_date, end_date strings, and redirect to index action
      start_date  = sprintf("%s", params[:start_date].split('/').reverse.swap!(1,2).join)
      end_date    = sprintf("%s", params[:end_date].split('/').reverse.swap!(1,2).join)
      redirect_to url_for(:action => 'show', :start_date => start_date, :end_date => end_date, :subdomain => current_subdomain)
    end
  end
  
  # GET /users/1/calendar/edit
  def edit
    if params[:schedulable_type].blank? or params[:schedulable_id].blank?
      # redirect to a specific schedulable
      schedulable = current_company.schedulables.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :schedulable_type => schedulable.tableize, :schedulable_id => schedulable.id)) and return
    end
        
    # initialize schedulable, default to anyone
    @schedulable  = current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:schedulable_id], params[:schedulable_type].to_s.classify)
    @schedulable  = User.anyone if @schedulable.blank?
    
    # build list of schedulables to allow the scheduled to be adjusted by resource
    @schedulables = current_company.schedulables.all
    
    # initialize daterange, start calendar on sunday, end calendar on sunday
    @daterange    = DateRange.parse_when('next 4 weeks', :start_on => 0, :end_on => 0)
        
    # find free work appointments
    @free_work_appts    = AppointmentScheduler.find_free_work_appointments(current_company, current_location, @schedulable, @daterange)

    # group appointments by day
    @free_work_appts_by_day = @free_work_appts.group_by { |appt| appt.start_at.utc.beginning_of_day }
    
    # build calendar markings
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
  
end