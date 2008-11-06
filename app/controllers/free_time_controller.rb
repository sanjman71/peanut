class FreeTimeController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # GET /free_time
  # GET /free_time.xml
  # GET /resources/1/free_time
  def index
    if params[:resource_id] == "0"
      # /resources/0/free_time is canonicalized to /free_time
      # preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :resource_id => nil)))
    end
    
    # initialize resource from parameter, default to anyone
    @resource = Resource.find(params[:resource_id]) if params[:resource_id]
    @resource = Resource.anyone if @resource.blank?
    
    # initialize time, job parameters
    @start_day  = Time.now.beginning_of_day
    @today      = @start_day
    @total_days = 14
    job         = Job.new(:duration => 0)
    
    logger.debug("*** finding free time in the next week")
    # build appointment request for the timespan we're looking for
    @request_appointment = AppointmentRequest.new(:start_at => @start_day, :end_at => @start_day + @total_days.days, :job => job, 
                                                  :resource => @resource, :company => @current_company)

    # find free appointments
    @free_appointments  = @request_appointment.find_free_appointments

    logger.debug("*** found #{@free_appointments.size} free timeslots")
        
    # find resources collection
    @resources = Resource.all + Array(Resource.anyone)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @appointments }
    end
  end

end
