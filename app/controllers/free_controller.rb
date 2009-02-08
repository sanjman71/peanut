class FreeController < ApplicationController
  # privilege_required 'read companies', :only => [:index]

  # GET /people/1/free/daily
  def new
    if params[:person_id].blank?
      # redirect to a specific person
      person = current_company.people.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :person_id => person.id)) and return
    end
        
    # initialize person, default to anyone
    @person     = current_company.people.find(params[:person_id]) if params[:person_id]
    @person     = Person.anyone if @person.blank?
    
    # initialize daterange and calendar markings
    @daterange  = DateRange.parse_when('next 4 weeks')
    @events     = {}
    
    # xxx - adjust the daterange 
    # xxx - we need a better way to start the calendar on a specified day of the week
    @daterange.start_at = Date.today - 3.days
    @daterange.days     += 3
    
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
    
    # iterate over specified time ranges
    params[:time_range].each do |time_range|
      time_range_index  = time_range.delete(:index).to_i
      appointment_hash  = base_hash.merge(:time_range => time_range)
      
      # build new appointment
      @appointment      = Appointment.new(appointment_hash)
                                                      
      # check if appointment is valid
      if !@appointment.valid?
        @error      = true
        @error_text = "#{@appointment.errors.full_messages}" # TODO: cleanup this error message
        logger.debug("xxx create free time error: #{@appointment.errors.full_messages}")
        @errors[time_range_index] = @appointment.errors.full_messages.join(", ")
      else
        logger.debug("*** valid free time")
        @success[time_range_index] = "Added available time on #{appointment_free_time_scheduled_at(@appointment)}"
      end
    end # time_range
    
    logger.debug("*** errors: #{@errors}")
    logger.debug("*** success: #{@success}")
    
    respond_to do |format|
      format.js
    end
  end
  
  protected
  
  def appointment_free_time_scheduled_at(appointment)
    "#{appointment.start_at.to_s(:appt_short_month_day_year)} from #{appointment.start_at.to_s(:appt_time)} to #{appointment.end_at.to_s(:appt_time)}"
  end
  
end
