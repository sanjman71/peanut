class OpeningsController < ApplicationController
  before_filter :init_current_company

  # GET /openings
  # GET /people/1/services/3/openings?when=this+week&time=morning
  # GET /services/1/openings?time=anytime&when=this+week
  def index
    if params[:person_id].to_s == "0"
      # /people/0/free is canonicalized to /free; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :person_id => nil)))
    elsif params[:service_id].to_s == "0"
      # /services/0/free is redirected to force the user to select a service; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :service_id => nil)))
    end
    
    # initialize person, default to anyone
    @person   = @current_company.people.find(params[:person_id]) if params[:person_id]
    @person   = Person.anyone if @person.blank?
    
    # initialize when, no default
    @when       = params[:when]
    @daterange  = DateRange.parse_when(@when) unless @when.blank?
    
    # initialize time
    @time       = params[:time]

    # initialize service, default to nothing
    @service    = @current_company.services.find_by_id(params[:service_id].to_i) || Service.nothing

    # build appointment request for the selected timespan
    @query      = AppointmentRequest.new(:service => @service, :resource => @person, :when => @when, :time => @time, :company => @current_company,
                                         :location => @current_location)

    # build people collection, people are restricted by the services they perform
    @people     = Array(Person.anyone) + @service.people
    
    # find services collection, services are restricted by the company they belong to
    @services   = Array(Service.nothing(:name => "Select a service")) + @current_company.services.work

    if @when.blank?
      logger.debug("*** showing empty page with help text")
      # render empty page with help text
      return
    end

    logger.debug("*** finding free time #{@when}")
    
    # find free appointments, and free timeslots for each free apppointment
    @free_appointments  = @query.find_free_appointments
    @free_timeslots     = @free_appointments.inject([]) do |timeslots, free_appointment|
      timeslots += @query.find_free_timeslots(:appointments => free_appointment, :limit => 2)
    end
    @free_timeslots_by_day = @free_timeslots.group_by { |timeslot| timeslot.start_at.beginning_of_day }
    
    logger.debug("*** found #{@free_appointments.size} free appointments, #{@free_timeslots.size} free timeslots over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings = @free_timeslots.inject(Hash.new) do |hash, timeslot|
      hash[timeslot.start_at.beginning_of_day.utc.to_s(:appt_schedule_day)] = 'free'
      hash
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @appointments }
    end
  end

  # temporary fix to format problem
  # why does params have 'authenticity_token' ???
  def search
    # remove 'authenticity_token' params
    params.delete('authenticity_token')
    redirect_to url_for(params.update(:subdomain => @subdomain, :action => 'index'))
  end
  
end
