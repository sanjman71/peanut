class OpeningsController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # GET /free
  # GET /free.xml
  # GET /resources/1/free
  # GET /resources/1/services/3/free
  # GET /resources/1/services/3/free?when=tomorrow
  def index
    if params[:resource_id].to_s == "0"
      # /resources/0/free is canonicalized to /free; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :resource_id => nil)))
    elsif params[:service_id].to_s == "0"
      # /services/0/free is redirected to force the user to select a service; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :service_id => nil, :when => nil)))
    end
    
    # initialize resource, default to anyone
    @resource = Resource.find(params[:resource_id]) if params[:resource_id]
    @resource = Resource.anyone if @resource.blank?
    
    # initialize when, no default
    @when       = params[:when]
    @daterange  = DateRange.new(:when => @when) unless @when.blank?
    
    # initialize service, default to nothing
    @service    = Service.find_by_id(params[:service_id].to_i) || Service.nothing
        
    # build appointment request for the timespan we're looking for
    @query      = AppointmentRequest.new(:when => @when, :service => @service, :resource => @resource, :company => @current_company)

    # find resources collection
    @resources  = Resource.all + Array(Resource.anyone)
    
    # find services collection
    @services   = Array(Service.nothing(:name => "Select a service")) + Service.work

    if @when.blank?
      # render empty page with help text
      return render
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
