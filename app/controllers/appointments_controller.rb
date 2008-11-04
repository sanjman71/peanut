class AppointmentsController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # GET /appointments
  # GET /appointments.xml
  def index
    # scope appointments by 'when'
    @when         = params[:when] ? params[:when ].to_sym : :upcoming
    
    # find appointments
    @appointments = Appointment.company(@current_company.id).send(@when)
    
    # group appointments by day
    @appt_days    = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
    
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
    if request.post?
      @appointment  = Appointment.new(params[:appointment])
      @suggest      = params[:suggest].to_i == 1
      
      begin
        if @suggest
          # suggest a time range
          @appointment.when = "next week"
        end
        
        # find free appointments for a job and resource within a time range
        @free_appointments  = @appointment.find_free_time(:limit => 3, :job => @appointment.job)
        @free_appt_days     = @free_appointments.group_by { |appt| appt.start_at.beginning_of_day }
      rescue Exception => e
        @free_appointments  = []
        logger.debug("*** exception: #{e}, #{@appointment.errors.full_messages}")
      end
    elsif request.get?
      # show form to search for free time
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
  
  # POST /appointments/confirm
  # POST /appointments/confirm.xml
  def confirm
    @appointment = Appointment.new(params[:appointment])

    if @appointment.errors.size > 0
      logger.debug("*** we have errors")
    end
    
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
  
end
