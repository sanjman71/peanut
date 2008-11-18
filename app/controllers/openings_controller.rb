class OpeningsController < ApplicationController
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

  # # GET /resources/1/free/manage
  # def manage
  #   if params[:resource_id].blank?
  #     # redirect to a specific resource
  #     resource = @current_company.resources.first
  #     redirect_to url_for(params.update(:subdomain => @subdomain, :resource_id => resource.id))
  #   end
  #   
  #   manage_shared
  # end
  #   
  # # POST /resources/1/create
  # def create
  #   # build new appointment
  #   job_free      = Job.free.first
  #   customer      = Customer.nobody
  #   @appointment  = Appointment.new(params[:appointment].merge(:resource_id => params[:resource_id], 
  #                                                              :job_id => job_free.id,
  #                                                              :company_id => @current_company.id,
  #                                                              :customer_id => customer.id))
  #   
  #   # check if appointment is valid                                                           
  #   if !@appointment.valid?
  #     @error      = true
  #     @error_text = ''
  #     logger.debug("*** create free time error: #{@appointment.errors.full_messages}")
  #     return
  #   end
  # 
  #   # check for conflicts
  #   if @appointment.conflicts?
  #     @error      = true
  #     @error_text = "Appointment conflict"
  #     logger.debug("*** create free time error: #{@appointment.errors.full_messages}")
  #     return
  #   end
  #   
  #   # save appointment
  #   @appointment.save
  #   @notice_text = "Created free time"
  # 
  #   logger.debug("*** created free time")
  #       
  #   manage_shared
  # end
  # 
  # # DELETE /resources/1/destroy
  # def destroy
  #   @appointment  = Appointment.find(params[:id])
  #   @appointment.destroy
  #   @notice_text  = "Deleted appointment"
  #   
  #   logger.debug("*** deleted appointment #{@appointment.id}")
  #       
  #   manage_shared
  # end
  # 
  # # shared method for managing free time used by manage action and create rjs action
  # def manage_shared
  #   # initialize resource, default to anyone
  #   @resource     = Resource.find_by_id(params[:resource_id])
  #   @resources    = Resource.all
  # 
  #   # initialize time parameters
  #   @when         = params[:when] || 'this week'
  #   @daterange    = DateRange.new(:when => @when)
  #   
  #   # find free, work appointments for a resource
  #   @appointments = Appointment.company(@current_company.id).resource(@resource.id).free_work.span(@daterange.start_at, @daterange.end_at).all(:order => 'start_at')
  #       
  #   logger.debug("*** found #{@appointments.size} appointments over #{@daterange.days} days")
  #   
  #   # build hash of calendar markings
  #   @calendar_markings = @appointments.inject(Hash.new) do |hash, appointment|
  #     hash[appointment.start_at.beginning_of_day.utc.to_s(:appt_schedule_day)] = appointment.mark_as
  #     hash
  #   end
  # 
  #   logger.debug("*** calendar markings: #{@calendar_markings}")
  #   
  #   # group appointments by day
  #   @appointments_by_day = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
  # end
  
end
