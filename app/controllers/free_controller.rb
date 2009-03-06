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
    # get appointment parameters
    @service      = current_company.services.find_by_id(params[:service_id])
    klass, id     = params[:schedulable].split('/')
    # note: the send method can generate an exception
    @schedulable  = current_company.send(klass).find_by_id(id)
    @customer     = User.find_by_id(params[:customer_id])
    
    # track valid and invalid appointments
    @errors       = Hash.new
    @success      = Hash.new
    
    @start_at     = params[:start_at]
    @end_at       = params[:end_at]
    
    # iterate over the specified dates
    Array(params[:dates]).each do |date|
      # build time range
      @time_range = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)

      begin
        case @service.mark_as
        when Appointment::WORK
          # create work appointment
          @appointment = AppointmentScheduler.create_work_appointment(current_company, @schedulable, @service, @customer, :time_range => @time_range)
        when Appointment::FREE
          # create free appointment
          @appointment = AppointmentScheduler.create_free_appointment(current_company, @schedulable, @service, :time_range => @time_range)
        end
        
        logger.debug("*** created #{@appointment.mark_as} appointment")
        @success[date] = "Created #{@appointment.mark_as} appointment on #{appointment_free_time_scheduled_at(@appointment)}"
      rescue Exception => e
        logger.debug("xxx create appointment error: #{e.message}")
        @errors[date] = e.message
      end
    end
    
    logger.debug("*** errors: #{@errors}")
    logger.debug("*** success: #{@success}")
    
    if @errors.keys.size > 0
      flash[:error]   = "There were #{@errors.keys.size} errors creating appointments"
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
