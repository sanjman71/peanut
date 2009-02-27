class AppointmentsController < ApplicationController
  
  # Default when value
  @@default_when = Appointment::WHEN_THIS_WEEK
  
  # GET /people/1/appointments
  def index
    if params[:customer_id]
      @customer     = User.find(params[:customer_id])
      @appointments = @customer.appointments
      raise Exception, "todo: show customer appointments: #{@appointments.size}"
    end

    if current_company.people_count == 0
      # show message that people need to be added before viewing schedules
      return
    end
    
    if params[:person_id].blank?
      # redirect to a specific person
      person = current_company.people.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :person_id => person.id)) and return
    end
    
    manage_appointments
  end
    
  # POST /people/1/create
  def create
    # build new free appointment
    service       = current_company.services.free.first
    person        = current_company.resources.find(params[:person_id])
    @appointment  = Appointment.new(params[:appointment].merge(:resource => person,
                                                               :service => service,
                                                               :company => current_company,
                                                               :location_id => current_location.id))
    
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
        
    # check waitlist for any possible openings because of this new free appointment
    WaitlistWorker.async_check_appointment_waitlist(:id => @appointment.id)
    
    manage_appointments
  end
  
  # DELETE /appointments/1
  def destroy
    @appointment  = current_company.appointments.find(params[:id])
    @appointment.destroy
    
    # set flash
    flash[:notice] = "Deleted appointment"
    logger.debug("*** deleted appointment #{@appointment.id}")
        
    if @appointment.waitlist?
      # redirect to waitlist index
      @redirect = waitlist_index_path(:subdomain => current_subdomain)
    else
      # redirect to person's appointment path 
      @person   = @appointment.resource
      @redirect = person_appointments_path(@person)
    end
  end
  
  # shared method for managing free/work appointments
  def manage_appointments
    # initialize person, default to anyone
    @person       = current_company.people.find_by_id(params[:person_id])
    @people       = current_company.people.all

    # initialize time parameters
    @when         = (params[:when] || @@default_when).from_url_param
    @daterange    = DateRange.parse_when(@when)
    
    # find free, work appointments for a person
    @appointments = current_company.appointments.resource(@person).free_work.overlap(@daterange.start_at, @daterange.end_at).general_location(@current_location.id).order_start_at
        
    logger.debug("*** found #{@appointments.size} appointments over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings = build_calendar_markings(@appointments)

    logger.debug("*** calendar markings: #{@calendar_markings}")
    
    # group appointments by day
    @appointments_by_day = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
  end

  # GET   /schedule/people/1/services/1/20081231T000000
  # POST  /schedule/people/1/services/1/20081231T000000
  # GET   /waitlist/people/3/services/8/this week/anytime
  # POST  /waitlist/people/3/services/8/this week/anytime
  def new
    # build appointment hash differently for schedule vs waitlist appointment requests
    hash = {:service_id => params[:service_id], :resource_id => params[:person_id], :resource_type => 'Person', :company_id => current_company.id}
    
    if request.url.match(/\/waitlist\//)
      # add when, time, mark_as attributes
      hash.update(:time => params[:time], :when => params[:when], :mark_as => Appointment::WAIT)
    elsif request.url.match(/\/schedule\//)
      # add start_at attribute
      hash.update(:start_at => params[:start_at])
    else
      raise ArgumentError
    end

    if logged_in?
      # fill in owner id from current user
      params[:appointment] ||= {}
      params[:appointment][:owner_id] = current_user.id
    end

    # add appointment attributes
    hash.update(params[:appointment]) if params[:appointment]
    
    # build appointment object
    @appointment = Appointment.new(hash)
    
    logger.debug("*** appointment waitlist: #{@appointment.waitlist?}, valid: #{@appointment.valid?}, #{@appointment.errors.full_messages.join(",")}")
    
    if !@appointment.valid?
      # ask for owner/user info
      logger.debug("*** appointment is missing owner info")
      return
    end
    
    if @appointment.waitlist?
      # add waitlist appointment
      logger.debug("*** adding waitlist appointment")
      
      begin
        @appointment.save!

        # send waitlist confirmation
        MailWorker.async_send_waitlist_confirmation(:id => @appointment.id)

        if @appointment.owner.sms?
          # send sms waitilist confirmation 
          SmsWorker.async_send_waitlist_confirmation(:id => @appointment.id)
        end
      rescue Exception => e
        logger.debug("*** could not create waitlist appointment: #{e.message}")
        return
      end

      # show waitlist
      return redirect_to(waitlist_index_path)
    elsif @appointment.conflicts?
      # resolve conflicts and schedule
      logger.debug("*** found appointment conflicts, resolving and scheduling the appointment")
      
      begin
        # create work appointment
        @work_appointment = AppointmentScheduler.create_work_appointment(@appointment)
        
        # send appointment confirmation
        MailWorker.async_send_appointment_confirmation(:id => @work_appointment.id)
      rescue Exception => e
        logger.debug("*** could not schedule appointment: #{e.message}")
        return
      end

      # show appointment confirmation
      return redirect_to(confirmation_appointment_path(@work_appointment))
    end
  end
  
  # GET /appointments/1
  # GET /appointments/1.xml
  def show
    @appointment  = current_company.appointments.find(params[:id])
    @note         = Note.new
    @confirmation = params[:confirmation].to_i == 1
    
    # invoices for completed appointments
    @invoice      = @appointment.invoice
    @services     = current_company.services.work.all
    @products     = current_company.products.instock
    @mode         = :r
    
    # build notes collection, most recent first 
    @notes        = @appointment.notes.sort_recent
  end
  
  # GET /appointments/1/confirmation
  def confirmation
    @appointment  = current_company.appointments.find(params[:id])
    
    # only show confirmations for upcoming appointments
    unless @appointment.state == 'upcoming'
      return redirect_to(appointment_path(@appointment))
    end
    
    # render show action
    render_component(:action => 'show', :id => @appointment.id, :params => {:confirmation => 1})
  end

  # GET /appointments/1/checkout - show invoice
  # PUT /appointments/1/checkout - mark appointment as checked-out/completed
  def checkout
    @appointment  = current_company.appointments.find(params[:id])
    
    if request.put?
      # mark appointment as checked-out/completed
      @appointment.checkout!

      # redirect to show action
      redirect_to(appointment_path(@appointment, :subdomain => @subdomain))
    else
      # create/get invoice
      @invoice    = @appointment.invoice || (@appointment.invoice = AppointmentInvoice.create; @appointment.invoice)

      # redirect to invoices controller
      redirect_to(invoice_path(@invoice, :subdomain => current_subdomain))
    end
  end

  # GET /appointments/1/cancel
  def cancel
    @appointment  = Appointment.find(params[:id])
    @person       = @appointment.resource
    
    # cancel the work appointment
    AppointmentScheduler.cancel_work_appointment(@appointment)
    
    # redirect to the resource's schedule page
    respond_to do |format|
      format.js
      format.html { redirect_to(person_appointments_path(@person)) }
    end
  end
  
  # GET /appointments/search
  def search
    if request.post?
      # check confirmation code, limit search to work appointments
      @code         = params[:appointment][:code].to_s.strip
      @appointment  = Appointment.work.find_by_confirmation_code(@code)
      
      if @appointment
        # redirect to appointment show
        @redirect = appointment_path(@appointment, :subdomain => @subdomain)
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
