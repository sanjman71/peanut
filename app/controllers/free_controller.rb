class FreeController < ApplicationController
  # privilege_required 'read companies', :only => [:index]

  # GET /users/1/free/calendar
  def new
    if params[:schedulable].blank? or params[:id].blank?
      # redirect to a specific schedulable
      schedulable = current_company.schedulables.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :schedulable => schedulable.tableize, :id => schedulable.id)) and return
    end
        
    # initialize schedulable, default to anyone
    @schedulable  = current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:id], params[:schedulable].to_s.classify)
    @schedulable  = User.anyone if @schedulable.blank?
    
    # build list of schedulables to allow the scheduled to be adjusted by resource
    @schedulables = current_company.schedulables.all
    
    # initialize daterange, start calendar on sunday, end calendar on sunday
    @daterange    = DateRange.parse_when('next 4 weeks', :start_on => 0, :end_on => 0)
    
    # find unscheduled time
    @unscheduled_appts  = AppointmentScheduler.find_unscheduled_time(current_company, @schedulable, @daterange)
    
    # build calendar markings
    @calendar_markings  = build_calendar_markings(@unscheduled_appts.values.flatten)
    
    # build time of day collection
    # TODO xxx - need a better way of mapping these times to start, end hours
    @tod        = ['morning', 'afternoon']
    @tod_start  = 'morning'
    @tod_end    = 'afternoon'
    
    @free_service = current_company.services.free.first

    # select the view to show
    style       = params[:style] || 'block'
    
    respond_to do |format|
      format.html { render(:action => "free_#{style}")}
    end
  end
  
  # POST /users/1/free
  def create
    # build new free appointment base parameters
    @service      = current_company.services.find_by_id(params[:service_id])
    klass, id     = params[:schedulable].split('/')
    @schedulable  = current_company.send(klass).find_by_id(id)
    base_hash     = Hash[:schedulable => @schedulable, :service => @service, :company => current_company, :location_id => current_location.id]
    
    # track valid and invalid appointments
    @errors       = Hash.new
    @success      = Hash.new
    
    @start_at     = params[:start_at]
    @end_at       = params[:end_at]
    
    # iterate over specified day
    Array(params[:dates]).each do |date|
      # build new appointment
      @time_range   = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)
      @appointment  = Appointment.new(base_hash.merge(:time_range => @time_range))
                                                      
      # check if appointment is valid
      if !@appointment.valid?
        @error_text = "#{@appointment.errors.full_messages}" # TODO: cleanup this error message
        logger.debug("xxx create free time error: #{@appointment.errors.full_messages}")
        @errors[date] = @appointment.errors.full_messages.join(", ")
      else
        # create appointment
        @appointment.save
        logger.debug("*** valid free time")
        @success[date] = "Added available time on #{appointment_free_time_scheduled_at(@appointment)}"
      end
    end
    
    logger.debug("*** errors: #{@errors}")
    logger.debug("*** success: #{@success}")
    
    if @errors.keys.size > 0
      flash[:error]   = "There were #{@errors.keys.size} errors creating available time"
      @redirect       = url_for(:action => 'new', :style => 'calendar', :subdomain => current_subdomain) 
    else
      flash[:notice]  = "Created available time"
      @redirect       = url_for(:action => 'new', :style => 'calendar', :subdomain => current_subdomain) 
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  protected
  
  def appointment_free_time_scheduled_at(appointment)
    "#{appointment.start_at.to_s(:appt_short_month_day_year)} from #{appointment.start_at.to_s(:appt_time)} to #{appointment.end_at.to_s(:appt_time)}"
  end
  
end
