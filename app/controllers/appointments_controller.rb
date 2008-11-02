class AppointmentsController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # GET /appointments
  # GET /appointments.xml
  def index
    # find all appointments scoped by current company
    @appointments = Appointment.company(@current_company.id)
    
    # group appointments by day
    @appt_days   = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
    
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

  # GET /appointments/new
  # GET /appointments/new.xml
  def new
    # build new appointment and customer objects
    @appointment = Appointment.new
    @appointment.customer = Customer.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @appointment }
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
        format.html { render :action => "new" }
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
  
  # GET /appointments/schedule
  def schedule
    if request.post?
      begin
        # find free appointments for a job and resource within a time range
        @appointment        = Appointment.new(params[:appointment])
        @partial            = :free
        @free_appointments  = @appointment.find_free_time(:limit => 3, :job_id => @appointment.job.id)
        @free_appt_days     = @free_appointments.group_by { |appt| appt.start_at.beginning_of_day }
      rescue Exception => e
        @free_appointments  = []
        logger.debug("*** exception: #{e}")
      end
    elsif request.put?
      # schedule the appointment
      @appointment  = Appointment.new(params[:appointment])
      @partial      = :customer
    else
      @appointment  = Appointment.new
      @jobs         = Job.work
      @resources    = Resource.company(@current_company.id)
    end
    
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @appointment }
      format.js   
    end
  end
end
