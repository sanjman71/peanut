class FreeController < ApplicationController
  # privilege_required 'read companies', :only => [:index]

  # GET /users/1/free/calendar
  def new
    if params[:resource].blank? or params[:id].blank?
      # redirect to a specific resource
      resource = current_company.resources.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :resource => resource.tableize, :id => resource.id)) and return
    end
        
    # initialize resource, default to anyone
    @resource   = current_company.resources.find_by_resource_id_and_resource_type(params[:id], params[:resource].to_s.classify)
    @resource   = User.anyone if @resource.blank?
    
    # build list of resources to allow the scheduled to be adjusted by resource
    @resources  = current_company.resources.all
    
    # initialize daterange, start calendar on sunday, end calendar on sunday
    @daterange  = DateRange.parse_when('next 4 weeks', :start_on => 0, :end_on => 0)
    
    # find unscheduled time
    @unscheduled_appts  = AppointmentScheduler.find_unscheduled_time(current_company, @resource, @daterange)
    
    # build calendar markings
    @calendar_markings  = build_calendar_markings(@unscheduled_appts.values.flatten)
    
    # build time of day collection
    # TODO xxx - need a better way of mapping these times to start, end hours
    @tod        = ['morning', 'afternoon']
    @tod_start  = 'morning'
    @tod_end    = 'afternoon'
    
    # select the view to show
    style       = params[:style] || 'block'
    
    respond_to do |format|
      format.html { render(:action => "free_#{style}")}
    end
  end
  
  # POST /people/1/free/create
  def create
    # build new free appointment base parameters
    service       = current_company.services.free.first
    person        = current_company.resources.find(params[:person_id])
    base_hash     = Hash[:resource => person, :service => service, :company => current_company, :location_id => current_location.id]
    
    # track valid and invalid appointments
    @errors       = Hash.new
    @success      = Hash.new
    
    @start_at     = params[:start_at]
    @end_at       = params[:end_at]
    
    # iterate over specified day
    params[:days].each do |day|
      # build new appointment
      time_range    = TimeRange.new(:day => day, :start_at => @start_at, :end_at => @end_at)
      @appointment  = Appointment.new(base_hash.merge(:time_range => time_range))
                                                      
      # check if appointment is valid
      if !@appointment.valid?
        @error_text = "#{@appointment.errors.full_messages}" # TODO: cleanup this error message
        logger.debug("xxx create free time error: #{@appointment.errors.full_messages}")
        @errors[day] = @appointment.errors.full_messages.join(", ")
      else
        # create appointment
        @appointment.save
        logger.debug("*** valid free time")
        @success[day] = "Added available time on #{appointment_free_time_scheduled_at(@appointment)}"
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
