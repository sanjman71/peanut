class AppointmentsController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # GET /resources/1/appointments
  def index
    if params[:customer_id]
      @customer     = Customer.find(params[:customer_id])
      @appointments = @customer.appointments
      raise Exception, "show customer appointments: #{@appointments.size}"
    end
    
    if params[:resource_id].blank?
      # redirect to a specific resource
      resource = @current_company.resources.first
      redirect_to url_for(params.update(:subdomain => @subdomain, :resource_id => resource.id))
    end
    
    manage_appointments
  end
    
  # POST /resources/1/create
  def create
    # build new free appointment
    service       = Service.free.first
    customer      = Customer.nobody
    @appointment  = Appointment.new(params[:appointment].merge(:resource_id => params[:resource_id], 
                                                               :service_id => service.id,
                                                               :company_id => @current_company.id,
                                                               :customer_id => customer.id))
    
    # check if appointment is valid                                                           
    if !@appointment.valid?
      @error      = true
      @error_text = ''
      logger.debug("*** create free time error: #{@appointment.errors.full_messages}")
      return
    end

    # check for conflicts
    if @appointment.conflicts?
      @error      = true
      @error_text = "Appointment conflict"
      logger.debug("*** create free time error: #{@appointment.errors.full_messages}")
      return
    end
    
    # save appointment
    @appointment.save
    @notice_text = "Created free time"

    logger.debug("*** created free time")
        
    manage_appointments
  end
  
  # DELETE /resources/1/destroy
  def destroy
    @appointment  = Appointment.find(params[:id])
    @appointment.destroy
    @notice_text  = "Deleted appointment"
    
    logger.debug("*** deleted appointment #{@appointment.id}")
        
    manage_appointments
  end
  
  # shared method for managing free/work appointments
  def manage_appointments
    # initialize resource, default to anyone
    @resource     = Resource.find_by_id(params[:resource_id])
    @resources    = Resource.all

    # initialize time parameters
    @when         = params[:when] || 'this week'
    @daterange    = DateRange.new(:when => @when)
    
    # find free, work appointments for a resource
    @appointments = Appointment.company(@current_company.id).resource(@resource.id).free_work.span(@daterange.start_at, @daterange.end_at).all(:order => 'start_at')
        
    logger.debug("*** found #{@appointments.size} appointments over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings = @appointments.inject(Hash.new) do |hash, appointment|
      hash[appointment.start_at.beginning_of_day.utc.to_s(:appt_schedule_day)] = appointment.mark_as
      hash
    end

    logger.debug("*** calendar markings: #{@calendar_markings}")
    
    # group appointments by day
    @appointments_by_day = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
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

  # GET /schedule/resources/1/services/1/20081231T000000
  # POST /schedule/resources/1/services/1/20081231T000000
  def new
    # build appointment hash
    hash = {:service_id => params[:service_id], :resource_id => params[:resource_id], :start_at => params[:start_at], :company_id => @current_company.id}
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
        # create work appointment by resolving the conflicting and re-arrange the free time
        @work_appointment = @appointment.schedule_work
        
        # send appointment confirmation
        MailWorker.async_appointment_confirmation(:id => @work_appointment.id)
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
  
  # GET /appointments/search
  def search
    
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

end
