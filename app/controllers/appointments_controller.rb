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
    
  # DELETE /appointments/1
  def destroy
    @appointment  = current_company.appointments.find(params[:id])
    @appointment.destroy
    
    # set flash
    flash[:notice] = "Deleted appointment"
    logger.debug("*** deleted appointment #{@appointment.id}")
        
    if @appointment.waitlist?
      # redirect to waitlist index
      @redirect_path  = waitlist_index_path(:subdomain => current_subdomain)
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

  # GET   /schedule/users/1/services/1/duration/60/20081231T000000
  # POST  /schedule/users/1/services/1/duration/60/20081231T000000
  # GET   /waitlist/users/1/services/8/this-week/anytime
  # POST  /waitlist/users/1/services/8/this-week/anytime
  def new
    if !logged_in?
      flash[:notice] = "To finalize your appointment, please log in or sign up."
      store_location
      redirect_to(login_path) and return
    end
    
    # get appointment parameters
    @service      = current_company.services.find_by_id(params[:service_id])
    # note: the send method can generate an exception
    @schedulable  = current_company.send(params[:schedulable_type]).find_by_id(params[:schedulable_id])
    @customer     = current_user
    
    case (@mark_as = params[:mark_as])
    when Appointment::WORK
      # schedule the work appointment without committing the changes
      @duration             = params[:duration].to_i if params[:duration]
      @start_at             = params[:start_at]
      @appointment          = AppointmentScheduler.create_work_appointment(current_company, @schedulable, @service, @duration, @customer, {:start_at => @start_at}, :commit => false)
    
      # show appointment date, start and end times in local time
      @appt_date            = @appointment.start_at.to_s(:appt_schedule_day)
      @appt_time_start_at   = @appointment.start_at.to_s(:appt_time_army)
      @appt_time_end_at     = @appointment.end_at.to_s(:appt_time_army)
    when Appointment::WAIT
      # build waitlist parameters
      @when                 = params[:when].from_url_param
      @time                 = params[:time].from_url_param
      @daterange            = DateRange.parse_when(@when)
      @options              = {:time => @time, :when => @when, :start_at => @daterange.start_at, :end_at => @daterange.end_at}
      # create waitlist object without committing the changes
      @appointment          = AppointmentScheduler.create_waitlist_appointment(current_company, @schedulable, @service, @customer, @options, :commit => false)
      
      # set appointment date to when parameter
      @appt_date            = @when.to_url_param
    end
  end
    
  def create
    # get appointment parameters
    @service      = current_company.services.find_by_id(params[:service_id])
    klass, id     = [params[:schedulable_type], params[:schedulable_id]]
    # note: the send method can generate an exception
    @schedulable  = current_company.send(klass).find_by_id(id)
    @customer     = User.find_by_id(params[:customer_id])

    @mark_as      = params[:mark_as]
    @duration     = params[:duration].to_i if params[:duration]
    @start_at     = params[:start_at]
    @end_at       = params[:end_at]
    
    # track errors and appointments created
    @errors       = Hash.new
    @success      = Hash.new
    
    # iterate over the specified dates
    Array(params[:dates]).each do |date|
      # build time range
      @time_range   = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)
      @options      = {:time_range => @time_range}

      begin
        case @mark_as
        when Appointment::WORK
          # create work appointment
          @appointment  = AppointmentScheduler.create_work_appointment(current_company, @schedulable, @service, @duration, @customer, @options, :commit => true)
          # send confirmation
          AppointmentScheduler.send_confirmation(@appointment, :email => true, :sms => false)
        when Appointment::FREE
          # create free appointment
          @appointment  = AppointmentScheduler.create_free_appointment(current_company, @schedulable, @service, @options)
        when Appointment::WAIT
          @when         = params[:when].from_url_param
          @time         = params[:time].from_url_param
          @daterange    = DateRange.parse_when(@when)
          @options      = {:time => @time, :when => @when, :start_at => @daterange.start_at, :end_at => @daterange.end_at}
          # create waitlist appointment
          @appointment  = AppointmentScheduler.create_waitlist_appointment(current_company, @schedulable, @service, @customer, @options, :commit => true)
          # send confirmation
          AppointmentScheduler.send_confirmation(@appointment, :email => true, :sms => false)
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
      @redirect_path  = url_for(:action => 'index', :schedulable_type => @schedulable.tableize, :schedulable_id => @schedulable.id, :subdomain => current_subdomain)
    else
      flash[:notice]  = "Created appointment(s)"
      @redirect_path  = url_for(:action => 'index', :schedulable_type => @schedulable.tableize, :schedulable_id => @schedulable.id, :subdomain => current_subdomain)
    end
    
    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
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
      redirect_to(appointment_path(@appointment)) and return
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
      redirect_to(appointment_path(@appointment, :subdomain => @subdomain)) and return
    else
      # create/get invoice
      @invoice    = @appointment.invoice || (@appointment.invoice = AppointmentInvoice.create; @appointment.invoice)

      # redirect to invoices controller
      redirect_to(invoice_path(@invoice, :subdomain => current_subdomain)) and return
    end
  end

  # GET /appointments/1/cancel
  def cancel
    @appointment  = Appointment.find(params[:id])
    @schedulable  = @appointment.schedulable
    
    # cancel the work appointment
    AppointmentScheduler.cancel_work_appointment(@appointment)
    
    # redirect to the schedule page
    @redirect_path = appointments_path(:schedulable => @schedulable.tableize, :id => @schedulable.id, :subdomain => current_subdomain)
    
    # set flash
    flash[:notice] = "Canceled appointment"
    
    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js
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
  
end
