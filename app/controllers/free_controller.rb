class FreeController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # GET /free
  # GET /free.xml
  # GET /resources/1/free
  # GET /resources/1/jobs/3/free
  # GET /resources/1/jobs/3/free?when=tomorrow
  def index
    if params[:resource_id].to_s == "0"
      # /resources/0/free is canonicalized to /free; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :resource_id => nil)))
    elsif params[:job_id].to_s == "0"
      # /jobs/0/free is redirected to force the user to select a job; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :job_id => nil, :when => nil)))
    end
    
    # initialize resource, default to anyone
    @resource = Resource.find(params[:resource_id]) if params[:resource_id]
    @resource = Resource.anyone if @resource.blank?
    
    # initialize when, no default
    @when       = params[:when]
    @daterange  = DateRange.new(:when => @when) unless @when.blank?
    
    # initialize job, default to first work job
    @job        = Job.find_by_id(params[:job_id].to_i) || Job.nothing
        
    # build appointment request for the timespan we're looking for
    @query      = AppointmentRequest.new(:when => @when, :job => @job, :resource => @resource, :company => @current_company)

    # find resources collection
    @resources  = Resource.all + Array(Resource.anyone)
    
    # find jobs collection
    @jobs       = Array(Job.nothing) + Job.work

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
    @free_days          = @free_timeslots.group_by { |timeslot| timeslot.start_at.beginning_of_day }
    
    logger.debug("*** found #{@free_appointments.size} free appointments, #{@free_timeslots.size} free timeslots")
            
    # initialize calendar params
    @start_day  = @daterange.start_at
    @total_days = @daterange.days
    @today      = Time.now.beginning_of_day
    
    logger.debug("*** total days #{@daterange.days}")
    
    # build hash of calendar markings
    @calendar_markings = @free_timeslots.inject(Hash.new) do |hash, timeslot|
      hash[timeslot.start_at.beginning_of_day.utc.to_s(:appt_schedule)] = 'free'
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

  # GET /resources/1/free/manage
  def manage
    if params[:resource_id].blank?
      # redirect to a specific resource
      resource = @current_company.resources.first
      redirect_to url_for(params.update(:subdomain => @subdomain, :resource_id => resource.id))
    end
    
    # initialize resource, default to anyone
    @resource     = Resource.find_by_id(params[:resource_id])
    @when         = params[:when] || 'this week'
    @daterange    = DateRange.new(:when => @when)
    
    @resources    = Resource.all
    
    # find free appointments for a resource
    @appointments = Appointment.company(@current_company.id).resource(@resource.id).free.span(@daterange.start_at, @daterange.end_at)
        
    # initialize calendar params
    @start_day    = @daterange.start_at
    @total_days   = @daterange.days
    @today        = Time.now.beginning_of_day
    
    logger.debug("*** found #{@appointments.size} appointments over #{@total_days} days")
    
    # build hash of calendar markings
    @calendar_markings = @appointments.inject(Hash.new) do |hash, appointment|
      hash[appointment.start_at.beginning_of_day.utc.to_s(:appt_schedule_day)] = appointment.mark_as
      hash
    end

    logger.debug("*** calendar markings: #{@calendar_markings}")
    
    # build hash of calendar appointments
    @calendar_appointments = @appointments.inject(Hash.new(Array.new)) do |hash, appointment|
      key = appointment.start_at.beginning_of_day.utc.to_s(:appt_schedule_day)
      logger.debug("*** hash key: #{key}")
      hash[appointment.start_at.beginning_of_day.utc.to_s(:appt_schedule_day)] += [appointment]
      logger.debug("*** hash: #{hash}")
      hash
    end

    logger.debug("*** calendar appointments: #{@calendar_appointments}")
    
    # group appointments by day
    @appt_days  = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
  end
  
  # GET /resources/1/free/20081231T060000/edit
  def edit
    # initialize resource
    @resource   = Resource.find(params[:resource_id])
    @day        = params[:id]
    @time       = Time.parse(params[:id])
  end

  # POST /resources/1/free/
  def create
    @resource     = Resource.find(params[:resource_id])
    
    # build new appointment
    @appointment  = Appointment.new(params[:appointment])
  end
  
  def update
    # build appointments from free time collection
    @appointments = params[:free_times].collect do |free_time|
      free_time = FreeTime.new(free_time)
      free_time.to_appointment
    end
    
    logger.debug("*** #{@appointments.size} appointments")
    
    # save appointments
    @appointments.each do |appointment|
      appointment.save
    end

    redirect_to new_resource_free_path(:subdomain => @subdomain)
  end
  
end
