class AppointmentsController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # GET /appointments
  # GET /appointments.xml
  # GET /resources/1/appointments
  # GET /resources/1//appointments.xml
  def index
    if params[:resource_id] == "0"
      # /resources/0/appointments is canonicalized to /appointments
      # preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => @subdomain, :resource_id => nil)))
    end
    
    # find resource, default to anyone
    @resource   = params[:resource_id] ? Resource.find(params[:resource_id]) : Resource.anyone
    
    # scope appointments by 'when', default to 'this week'
    @when       = params[:when] ? params[:when] : 'this week'
    @daterange  = DateRange.new(:when => @when)
    
    if @resource.anyone?
      # find all appointments
      @appointments = Appointment.company(@current_company.id).span(@daterange.start_at, @daterange.end_at)
    else
      # find appointments for a resource
      @appointments = Appointment.company(@current_company.id).resource(@resource.id).span(@daterange.start_at, @daterange.end_at)
    end
        
    # initialize calendar params
    @start_day  = @daterange.start_at
    @total_days = @daterange.days
    @today      = Time.now.beginning_of_day
    
    logger.debug("*** found #{@appointments.size} appointments over #{@total_days} days")

    # build hash of calendar markings
    @calendar_markings = @appointments.inject(Hash.new) do |hash, appointment|
      hash[appointment.start_at.beginning_of_day.utc.to_s(:appt_schedule_day)] = appointment.mark_as
      hash
    end
    
    logger.debug("*** calendar markings: #{@calendar_markings}")
    
    # group appointments by day
    @appt_days  = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
    
    # find resources collection
    @resources  = Resource.all + Array(Resource.anyone)
    
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

  # GET /appointments/1
  # GET /appointments/1.xml
  # def show
  #   @appointment = Appointment.find(params[:id])
  # 
  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.xml  { render :xml => @appointment }
  #   end
  # end

  # GET /schedule/resources/1/jobs/1/20081231T000000
  # POST /schedule/resources/1/jobs/1/20081231T000000
  def new
    # build appointment hash
    hash = {:job_id => params[:job_id], :resource_id => params[:resource_id], :start_at => params[:start_at], :company_id => @current_company.id}
    hash.update(params[:appointment]) if params[:appointment]
    
    # build appointment object
    @appointment  = Appointment.new(hash)
    
    logger.debug("*** appointment valid: #{@appointment.valid?}, #{@appointment.errors.full_messages.join(",")}")
    
    if !@appointment.valid?
      # ask for customer info
      logger.debug("*** appointment is missing customer info")
      return
    end
    
    # check for conflicts
    if @appointment.conflicts?
      logger.debug("*** found appointment conflicts, resolving and scheduling the appointment")
      
      begin
        @work_appointment = @appointment.schedule_work
      rescue Exception => e
        logger.debug("*** could not schedule appointment: #{e.message}")
        return
      end
    end

    # show appointment confirmation
    return redirect_to(confirmation_appointment_path(@work_appointment))
  end
  
  # GET /appointments/1/confirmation
  def confirmation
    @appointment = Appointment.find(params[:id])
  end
  
  # GET /appointments/1/edit
  # def edit
  #   @appointment = Appointment.find(params[:id])
  # end

  # POST /appointments
  # POST /appointments.xml
  # def create
  #   @appointment = Appointment.new(params[:appointment])
  # 
  #   respond_to do |format|
  #     if @appointment.save
  #       flash[:notice] = 'Appointment was successfully created.'
  #       format.html { redirect_to(@appointment) }
  #       format.xml  { render :xml => @appointment, :status => :created, :location => @appointment }
  #     else
  #       format.html { render :action => "confirm" }
  #       format.xml  { render :xml => @appointment.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end

  # PUT /appointments/1
  # PUT /appointments/1.xml
  # def update
  #   @appointment = Appointment.find(params[:id])
  # 
  #   respond_to do |format|
  #     if @appointment.update_attributes(params[:appointment])
  #       flash[:notice] = 'Appointment was successfully updated.'
  #       format.html { redirect_to(@appointment) }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render :action => "edit" }
  #       format.xml  { render :xml => @appointment.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /appointments/1
  # DELETE /appointments/1.xml
  # def destroy
  #   @appointment = Appointment.find(params[:id])
  #   @appointment.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(appointments_url) }
  #     format.xml  { head :ok }
  #   end
  # end
    
end
