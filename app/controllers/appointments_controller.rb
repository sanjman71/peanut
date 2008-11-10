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
    
    # find resource if specified
    @resource = Resource.find(params[:resource_id]) if params[:resource_id]
    
    # scope appointments by 'when'
    @when     = params[:when] ? params[:when ].to_sym : :upcoming
    
    if @resource
      # find resource appointments 
      @appointments = Appointment.company(@current_company.id).resource(@resource.id).send(@when)
    elsif
      # find all appointments
      @appointments = Appointment.company(@current_company.id).send(@when)
      @resource     = Resource.anyone
    end
    
    # group appointments by day
    @appt_days = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
    
    # find resources collection
    @resources = Resource.all + Array(Resource.anyone)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @appointments }
    end
  end

  # GET /appointments/1
  # GET /appointments/1.xml
  def show
    @appointment = Appointment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @appointment }
    end
  end

  # GET /schedule/resources/1/jobs/1/20081231T000000
  # POST /schedule/resources/1/jobs/1/20081231T000000
  def new
    # parse schedule request

    # build appointment hash
    hash = {:job_id => params[:job_id], :resource_id => params[:resource_id], :start_at => params[:start_at], :company_id => @current_company.id}
    hash.update(params["appointment"]) if params["appointment"]
    

    # build appointment object
    @appointment  = Appointment.new(hash)
    
    logger.debug("valid: #{@appointment.valid?}, #{@appointment.errors.full_messages.join(",")}")
    
    if @appointment.valid?
      # ask for custoemr info
    else
      
    end
  end
  
  # GET /appointments/1/edit
  def edit
    @appointment = Appointment.find(params[:id])
  end

  # POST /appointments
  # POST /appointments.xml
  def create
    @appointment = Appointment.new(params[:appointment])

    respond_to do |format|
      if @appointment.save
        flash[:notice] = 'Appointment was successfully created.'
        format.html { redirect_to(@appointment) }
        format.xml  { render :xml => @appointment, :status => :created, :location => @appointment }
      else
        format.html { render :action => "confirm" }
        format.xml  { render :xml => @appointment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /appointments/1
  # PUT /appointments/1.xml
  def update
    @appointment = Appointment.find(params[:id])

    respond_to do |format|
      if @appointment.update_attributes(params[:appointment])
        flash[:notice] = 'Appointment was successfully updated.'
        format.html { redirect_to(@appointment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @appointment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /appointments/1
  # DELETE /appointments/1.xml
  def destroy
    @appointment = Appointment.find(params[:id])
    @appointment.destroy

    respond_to do |format|
      format.html { redirect_to(appointments_url) }
      format.xml  { head :ok }
    end
  end
    
end
