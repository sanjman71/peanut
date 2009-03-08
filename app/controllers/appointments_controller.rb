class AppointmentsController < ApplicationController
  
  # Default when value
  @@default_when = Appointment::WHEN_THIS_WEEK
  
  # GET /schedulable/1/appointments/when/next-week
  # GET /schedulable/1/appointments/range/20090101..20090201
  def index
    if params[:customer_id]
      @customer     = User.find(params[:customer_id])
      @appointments = @customer.appointments
      raise Exception, "todo: show customer appointments: #{@appointments.size}"
    end
    
    @free_service = current_company.services.free.first

    if current_company.schedulables_count == 0
      # show message that schedulables need to be added before viewing schedules
      return
    end
    
    if params[:schedulable_type].blank? or params[:schedulable_id].blank?
      # redirect to a specific schedulable
      schedulable = current_company.schedulables.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :schedulable_type => schedulable.class.to_s.tableize, :schedulable_id => schedulable.id)) and return
    end
    
    manage_appointments
  end
    
  # POST /users/1/create
  # def create
  #   # build new free appointment
  #   service       = current_company.services.free.first
  #   schedulable   = current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:id], params[:schedulable].to_s.classify)
  #   @appointment  = Appointment.new(params[:appointment].merge(:schedulable => schedulable,
  #                                                              :service => service,
  #                                                              :company => current_company,
  #                                                              :location_id => current_location.id))
  #   
  #   # check if appointment is valid                                                           
  #   if !@appointment.valid?
  #     @error      = true
  #     @error_text = "#{@appointment.errors.full_messages}" # TODO: cleanup this error message
  #     logger.debug("xxx create free time error: #{@appointment.errors.full_messages}")
  #     return
  #   end
  # 
  #   # check for conflicts
  #   if @appointment.conflicts?
  #     @error      = true
  #     @error_text = "Appointment conflict"
  #     logger.debug("xxx create free time conflict: #{@appointment.errors.full_messages}")
  #     return
  #   end
  #   
  #   # save appointment
  #   @appointment.save
  #   @notice_text = "Created free time"
  # 
  #   logger.debug("*** created free time")
  #       
  #   begin
  #     # check waitlist for any possible openings because of this new free appointment
  #     WaitlistWorker.async_check_appointment_waitlist(:id => @appointment.id)
  #   rescue Exception => e
  #     logger.debug("*** could not check waitlist appointments: #{e.message}")
  #   end
  #   
  #   manage_appointments
  # end
  
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
      # redirect to schedulable appointment path
      @schedulable  = @appointment.schedulable
      @redirect     = url_for(:action => 'index', :schedulable_type => @schedulable.tableize, :schedulable_id => @schedulable.id, :subdomain => current_subdomain)
    end
  end
  
  # shared method for managing free/work appointments
  def manage_appointments
    # initialize resource, default to anyone
    @schedulable  = current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:schedulable_id], params[:schedulable_type].to_s.classify)
    @schedulables = current_company.schedulables.all

    if params[:start_date] and params[:end_date]
      # build daterange using range values
      @start_date = params[:start_date]
      @end_date   = params[:end_date]
      @daterange  = DateRange.parse_range(@start_date, @end_date)
    else
      # build daterange using when
      @when       = (params[:when] || @@default_when).from_url_param
      @daterange  = DateRange.parse_when(@when)
    end

    # find free, work appointments for a resource
    @appointments = current_company.appointments.schedulable(@schedulable).free_work.overlap(@daterange.start_at, @daterange.end_at).general_location(@current_location.id).order_start_at
        
    logger.debug("*** found #{@appointments.size} appointments over #{@daterange.days} days")
    
    # build hash of calendar markings
    @calendar_markings = build_calendar_markings(@appointments)

    logger.debug("*** calendar markings: #{@calendar_markings}")
    
    # group appointments by day
    @appointments_by_day = @appointments.group_by { |appt| appt.start_at.beginning_of_day }
  end

  # GET   /schedule/users/1/services/1/20081231T000000
  # POST  /schedule/users/1/services/1/20081231T000000
  # GET   /waitlist/users/3/services/8/this week/anytime
  # POST  /waitlist/users/3/services/8/this week/anytime
  def new
    # get appointment parameters
    @service      = current_company.services.find_by_id(params[:service_id])
    # note: the send method can generate an exception
    @schedulable  = current_company.send(params[:schedulable_type]).find_by_id(params[:schedulable_id])
    @customer     = current_user
    
    # @appointment = new_appointment_from_params()
    # logger.debug("*** appointment waitlist: #{@appointment.waitlist?}, valid: #{@appointment.valid?}, #{@appointment.errors.full_messages.join(",")}")
    
    if !logged_in?
      flash[:notice] = "To finalize your appointment, please log in or sign up."
      store_location
      redirect_to(login_path) and return
    end
    
    # try to schedule the work appointment without committing the changes
    @appointment = AppointmentScheduler.create_work_appointment(current_company, @schedulable, @service, @customer,
                                                                {:start_at => params[:start_at]}, :commit => 0)
  end
  
  # def create
  #   @appointment = new_appointment_from_params()
  # 
  #   if !@appointment.valid?
  #     # ask for customer/user info
  #     logger.debug("*** appointment is missing customer info")
  #     redirect_to schedule_path(:resource => params[:resource], :id => params[:id], :service_id => params[:service_id], :start_at => params[:start_at])
  #   else
  #     if @appointment.waitlist?
  #       # add waitlist appointment
  #       logger.debug("*** adding waitlist appointment")
  #     
  #       @appointment.save
  # 
  #       begin
  #         # send waitlist email confirmation
  #         MailWorker.async_send_waitlist_confirmation(:id => @appointment.id)
  #         flash[:notice] = "Sent email confirmation message for your waitlist appointment to #{appointment.owner.email}."
  #       rescue Exception => e
  #         flash[:error] = "Could not send email confirmation message for your waitlist appointment."
  #       end
  # 
  #       if @appointment.owner.sms?
  #         begin
  #           # send sms waitilist confirmation 
  #           SmsWorker.async_send_waitlist_confirmation(:id => @appointment.id)
  #           flash[:notice] = "Sent confirmation text message for your waitlist appointment to #{appointment.owner.phone}."
  #         rescue Exception => e
  #           flash[:error] = "Could not send confirmation text message for your waitlist appointment to  #{appointment.owner.phone}."
  #         end
  #       end
  # 
  #       # show waitlist
  #       return redirect_to(waitlist_index_path)
  #     elsif @appointment.conflicts?
  #       # resolve conflicts and schedule
  #       logger.debug("*** found appointment conflicts, resolving and scheduling the appointment")
  #     
  #       # create work appointment
  #       @work_appointment = AppointmentScheduler.create_work_appointment(@appointment)
  #     
  #       begin
  #         # send appointment confirmation
  #         MailWorker.async_send_appointment_confirmation(:id => @work_appointment.id)
  #       rescue Exception => e
  #         flash[:error] = "Could not send email confirmation message for your appointment."
  #       end
  # 
  #       # show appointment confirmation
  #       return redirect_to(confirmation_appointment_path(@work_appointment))
  #     end
  #   end
  # end
  
  def create
    # get appointment parameters
    @service      = current_company.services.find_by_id(params[:service_id])
    klass, id     = params[:schedulable].split('/')
    # note: the send method can generate an exception
    @schedulable  = current_company.send(klass).find_by_id(id)
    @customer     = User.find_by_id(params[:customer_id])
    
    # track valid and invalid appointments
    @errors       = Hash.new
    @success      = Hash.new
    
    @start_at     = params[:start_at]
    @end_at       = params[:end_at]
    
    # iterate over the specified dates
    Array(params[:dates]).each do |date|
      # build time range
      @time_range = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)

      begin
        case @service.mark_as
        when Appointment::WORK
          # create work appointment
          @appointment = AppointmentScheduler.create_work_appointment(current_company, @schedulable, @service, @customer, :time_range => @time_range)
        when Appointment::FREE
          # create free appointment
          @appointment = AppointmentScheduler.create_free_appointment(current_company, @schedulable, @service, :time_range => @time_range)
        end
        
        logger.debug("*** created #{@appointment.mark_as} appointment")
        @success[date] = "Created #{@appointment.mark_as} appointment"
      rescue Exception => e
        logger.debug("xxx create appointment error: #{e.message}")
        @errors[date] = e.message
      end
    end
    
    logger.debug("*** errors: #{@errors}")
    logger.debug("*** success: #{@success}")
    
    if @errors.keys.size > 0
      flash[:error]   = "There were #{@errors.keys.size} errors creating appointments"
      @redirect       = url_for(:action => 'index', :schedulable_type => @schedulable.tableize, :schedulable_id => @schedulable.id, :subdomain => current_subdomain)
    else
      flash[:notice]  = "Created appointment(s)"
      @redirect       = url_for(:action => 'index', :schedulable_type => @schedulable.tableize, :schedulable_id => @schedulable.id, :subdomain => current_subdomain)
    end
    
    respond_to do |format|
      format.js
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
    @resource     = @appointment.resource
    
    # cancel the work appointment
    AppointmentScheduler.cancel_work_appointment(@appointment)
    
    # redirect to the resource's schedule page
    respond_to do |format|
      format.js
      format.html { redirect_to(resource_appointments_path(:resource => @resource.class.to_s.tableize, :id => @resource.id, :subdomain => current_subdomain)) }
    end
  end
  
  # GET  /appointments/search
  # POST /appointments/search
  #  - search for an appointment by code => params[:appointment][:code]
  #  - search for appointments by date range => params[:start_date], params[:end_date]
  def search
    if request.post?
      if params[:appointment] and params[:appointment][:code]
        # check confirmation code, limit search to work appointments
        @code         = params[:appointment][:code].to_s.strip
        @appointment  = Appointment.work.find_by_confirmation_code(@code)
      
        if @appointment
          # redirect to appointment show
          @redirect = appointment_path(@appointment, :subdomain => current_subdomain)
        else
          # show error message?
          logger.debug("*** could not find appointment #{@code}")
        end
      elsif params[:start_date] and params[:end_date]
        # reformat start_date, end_date strings, and redirect to index action
        start_date  = sprintf("%s", params[:start_date].split('/').reverse.swap!(1,2).join)
        end_date    = sprintf("%s", params[:end_date].split('/').reverse.swap!(1,2).join)
        redirect_to url_for(:action => 'index', :start_date => start_date, :end_date => end_date, :subdomain => current_subdomain)
      end
    end
  end
    
  protected
  
  def appointment_free_time_scheduled_at(appointment)
    "#{appointment.start_at.to_s(:appt_short_month_day_year)} from #{appointment.start_at.to_s(:appt_time)} to #{appointment.end_at.to_s(:appt_time)}"
  end
  
  def new_appointment_from_params
    # build appointment hash differently for schedule vs waitlist appointment requests
    hash = {:service_id => params[:service_id], :resource_id => params[:id], :resource_type => params[:resource].to_s.classify, :company_id => current_company.id}
    
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
      # fill in customer id from current user
      params[:appointment] ||= {}
      params[:appointment][:customer_id] = current_user.id
    end

    # add appointment attributes
    hash.update(params[:appointment]) if params[:appointment]
    
    # build appointment object
    appointment = Appointment.new(hash)
    
    appointment
  end
  
end
