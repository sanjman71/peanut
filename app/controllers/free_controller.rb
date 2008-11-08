class FreeController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # GET /free_time
  # GET /free_time.xml
  # GET /resources/1/free_time
  # GET /resources/1/jobs/3/free_time
  # GET /resources/1/jobs/3/free_time?when=tomorrow
  def index
    if params[:resource_id] == "0"
      # /resources/0/free_time is canonicalized to /free_time
      # preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :resource_id => nil)))
    end
    
    # initialize resource, default to anyone
    @resource = Resource.find(params[:resource_id]) if params[:resource_id]
    @resource = Resource.anyone if @resource.blank?
    
    # initialize when, default to 'this week'
    @when     = params[:when] || 'this week'
    
    # initialize job, default to first work job
    @job      = Job.find_by_id(params[:job_id].to_i) || Job.work.first
        
    logger.debug("*** finding free time #{@when}")
    
    # build appointment request for the timespan we're looking for
    @query      = AppointmentRequest.new(:when => @when, :job => @job, :resource => @resource, :company => @current_company)

    # initialize calendar days
    @start_day  = @query.start_at.beginning_of_day #Time.now.beginning_of_day
    @end_day    = @query.end_at.end_of_day
    @total_days = (@end_day - @start_day).to_i / (60 * 60 * 24)
    @today      = Time.now.beginning_of_day

    # find free appointments and free timeslots for each free apppointment
    @free_appointments  = @query.find_free_appointments
    @free_timeslots     = @free_appointments.inject([]) do |timeslots, free_appointment|
      timeslots += @query.find_free_timeslots(:appointments => free_appointment, :limit => 2)
    end
    @free_days          = @free_timeslots.group_by { |timeslot| timeslot.start_at.beginning_of_day }
    
    logger.debug("*** found #{@free_appointments.size} free appointments, #{@free_timeslots.size} free timeslots")
        
    # find resources collection
    @resources  = Resource.all + Array(Resource.anyone)
    
    # find jobs collection
    @jobs       = Job.work
    
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
