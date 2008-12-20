class AppointmentsController < ApplicationController
  before_filter :init_current_company
  layout 'blueprint'
  
  # GET /people/1/appointments
  def index
    if params[:customer_id]
      @customer     = Customer.find(params[:customer_id])
      @appointments = @customer.appointments
      raise Exception, "show customer appointments: #{@appointments.size}"
    end
    
    if params[:person_id].blank?
      # redirect to a specific person
      person = @current_company.people.first
      redirect_to url_for(params.update(:subdomain => @subdomain, :person_id => person.id))
    end
    
    manage_appointments
  end
    
  # POST /people/1/create
  def create
    # build new free appointment
    service       = @current_company.services.free.first
    customer      = Customer.nobody
    person        = Person.find(params[:person_id])
    @appointment  = Appointment.new(params[:appointment].merge(:resource => person,
                                                               :service => service,
                                                               :company => @current_company,
                                                               :customer_id => customer.id))
    
    # check if appointment is valid                                                           
    if !@appointment.valid?
      @error      = true
      @error_text = "#{@appointment.errors.full_messages}" # TODO: cleanup this error message
      logger.debug("xxx create free time error: #{@appointment.errors.full_messages}")
      return
    end

    # check for conflicts
    if @appointment.conflicts?
      @error      = true
      @error_text = "Appointment conflict"
      logger.debug("xxx create free time conflict: #{@appointment.errors.full_messages}")
      return
    end
    
    # save appointment
    @appointment.save
    @notice_text = "Created free time"

    logger.debug("*** created free time")
        
    manage_appointments
  end
  
  # DELETE /people/1/destroy
  def destroy
    @appointment  = Appointment.find(params[:id])
    @appointment.destroy
    @notice_text  = "Deleted appointment"
    
    logger.debug("*** deleted appointment #{@appointment.id}")
        
    manage_appointments
  end
  
  # shared method for managing free/work appointments
  def manage_appointments
    # initialize person, default to anyone
    @person       = @current_company.people.find_by_id(params[:person_id])
    @people       = @current_company.people.all

    # initialize time parameters
    @when         = params[:when] || 'this week'
    @daterange    = DateRange.new(:when => @when)
    
    # find free, work appointments for a person
    @appointments = @current_company.appointments.resource(@person).free_work.overlap(@daterange.start_at, @daterange.end_at).all(:order => 'start_at')
        
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

  # GET /schedule/people/1/services/1/20081231T000000
  # POST /schedule/people/1/services/1/20081231T000000
  def new
    # build appointment hash
    hash = {:service_id => params[:service_id], :resource_id => params[:person_id], :resource_type => 'Person',
            :start_at => params[:start_at], :company_id => @current_company.id}
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
        # create work appointment
        @work_appointment = AppointmentScheduler.create_work_appointment(@appointment)
        
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
  
  # GET /appointments/1
  # GET /appointments/1.xml
  def show
    @appointment  = Appointment.find(params[:id])
    @note         = Note.new
    
    # build notes collection, most recent first 
    @notes        = @appointment.notes.sort_recent
    
    respond_to do |format|
      format.html { render :action => 'show' }
      format.xml  { render :xml => @appointment }
    end
  end
  
  # GET /appointments/1/confirmation
  def confirmation
    @appointment  = @current_company.appointments.find(params[:id])
    @confirmation = true
    
    # only show confirmations for upcoming appointments
    unless @appointment.state == 'upcoming'
      return redirect_to(appointment_path(@appointment))
    end
    
    # use show action
    show
  end

  # GET /appointments/1/checkout
  def checkout
    @appointment  = @current_company.appointments.find(params[:id])
    @services     = @current_company.services.all
    
    # create/get invoice
    @invoice      = @appointment.invoice || (@appointment.invoice = AppointmentInvoice.create; @appointment.invoice)
  end

  # GET /appointments/1/cancel
  def cancel
    @appointment  = Appointment.find(params[:id])
    @person       = @appointment.resource
    
    # cancel the work appointment
    AppointmentScheduler.cancel_work_appointment(@appointment)
    
    # redirect to the resource's schedule page
    return redirect_to(person_appointments_path(@person))
  end
  
  # GET /appointments/search
  def search
    if request.post?
      # check confirmation code, limit search to work appointments
      @code         = params[:appointment][:code]
      @appointment  = Appointment.work.find_by_confirmation_code(@code)
      
      if @appointment
        # redirect to appointment show
        @redirect = appointment_path(@appointment)
      else
        # show error message?
        logger.debug("*** could not find appointment #{@code}")
      end
    end
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
