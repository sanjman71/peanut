class AppointmentsController < ApplicationController
  before_filter :disable_global_flash, :only => [:show, :confirmation]
  
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
      # build the work appointment without committing the changes
      @duration             = params[:duration].to_i if params[:duration]
      @start_at             = params[:start_at]
      @options              = {:start_at => @start_at}
      @appointment          = AppointmentScheduler.create_work_appointment(current_company, @schedulable, @service, @duration, @customer, @options, :commit => false)
    
      # set appointment date, start_at and end_at times in local time
      @appt_date            = @appointment.start_at.to_s(:appt_schedule_day)
      @appt_time_start_at   = @appointment.start_at.to_s(:appt_time_army)
      @appt_time_end_at     = @appointment.end_at.to_s(:appt_time_army)
    when Appointment::WAIT
      # build waitlist parameters
      @daterange            = DateRange.parse_range(params[:start_date], params[:end_date], :inclusive => true)
      @options              = {:start_at => @daterange.start_at, :end_at => @daterange.end_at}
      # build the  waitlist appointment without committing the changes
      @appointment          = AppointmentScheduler.create_waitlist_appointment(current_company, @schedulable, @service, @customer, @options, :commit => false)
      
      # set appointment date to daterange name, set start_at and end_at times in schedule format
      @appt_date            = @daterange.name
      @appt_time_start_at   = @appointment.start_at.to_s(:appt_schedule_day)
      @appt_time_end_at     = @appointment.end_at.to_s(:appt_schedule_day)
    end

    respond_to do |format|
      format.html
    end
  end
    
  def create
    # get appointment parameters
    @service      = current_company.services.find_by_id(params[:service_id])
    klass, id     = [params[:schedulable_type], params[:schedulable_id]]
    @customer     = User.find_by_id(params[:customer_id])
        
    begin
      # find the schedulable, but beware that the send method can generate an exception
      @schedulable = current_company.send(klass).find_by_id(id)
    rescue Exception => e
      logger.debug("xxx create appointment error: #{e.message}")
      flash[:error] = "Error creating appointment"
      # set redirect path
      @redirect_path = request.referer
      return
    end
    
    @mark_as        = params[:mark_as]
    @duration       = params[:duration].to_i if params[:duration]
    @start_at       = params[:start_at]
    @end_at         = params[:end_at]
    
    # track errors and appointments created
    @errors         = Hash.new
    @created        = Hash.new
    
    # set default redirect path
    @redirect_path  = request.referer
    
    # check that the user has the privilege to create the specified appointment type
    if !has_privilege?("create #{@mark_as} appointments", current_company)
      redirect_to(unauthorized_path) and return
    end
    
    # iterate over the specified dates
    Array(params[:dates]).each do |date|
      begin
        case @mark_as
        when Appointment::WORK
          # build time range
          @time_range     = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)
          @options        = {:time_range => @time_range}
          # create work appointment
          @appointment    = AppointmentScheduler.create_work_appointment(current_company, @schedulable, @service, @duration, @customer, @options, :commit => true)
          # set redirect path
          @redirect_path  = confirmation_appointment_path(@appointment)
          flash[:notice]  = "Booked your #{@service.name} appointment"
          # send confirmation
          AppointmentScheduler.send_confirmation(@appointment, :email => true, :sms => false)
        when Appointment::FREE
          # build time range
          @time_range     = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)
          @options        = {:time_range => @time_range}
          # create free appointment
          @appointment    = AppointmentScheduler.create_free_appointment(current_company, @schedulable, @service, @options)
          # set redirect path
          @redirect_path  = request.referer
          flash[:notice]  = "Created available time"
        when Appointment::WAIT
          # build date range
          @daterange      = DateRange.parse_range(@start_at, @end_at, :inclusive => true)
          @options        = {:start_at => @daterange.start_at, :end_at => @daterange.end_at}
          # create waitlist appointment
          @appointment    = AppointmentScheduler.create_waitlist_appointment(current_company, @schedulable, @service, @customer, @options, :commit => true)
          # set redirect path
          @redirect_path  = confirmation_appointment_path(@appointment)
          flash[:notice]  = "Created your waitlist appointment"
          # send confirmation
          AppointmentScheduler.send_confirmation(@appointment, :email => true, :sms => false)
        end
        
        logger.debug("*** created #{@appointment.mark_as} appointment")
        @created[date] = "Created #{@appointment.mark_as} appointment"
      rescue Exception => e
        logger.debug("xxx create appointment error: #{e.message}")
        @errors[date] = e.message
      end
    end
    
    logger.debug("*** errors: #{@errors}")
    logger.debug("*** created: #{@created}")
    
    if @errors.keys.size > 0
      # set the flash
      flash[:error]   = "There were #{@errors.keys.size} errors creating appointments"
      @redirect_path  = build_create_redirect_path(@schedulable, request.referer)
    else
      @redirect_path  = @redirect_path || build_create_redirect_path(@schedulable, request.referer)
    end
    
    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js
    end
  end
  
  # GET /appointments/1
  def show
    @appointment  = current_company.appointments.find(params[:id])
    @note         = Note.new
    @confirmation = params[:confirmation].to_i == 1
    
    # show invoices for completed appointments
    @invoice      = @appointment.invoice
    @services     = current_company.services.work.all
    @products     = current_company.products.instock
    @mode         = :r
    
    # build notes collection, most recent first 
    @notes        = @appointment.notes.sort_recent

    respond_to do |format|
      format.html
    end
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
      @schedulable    = @appointment.schedulable
      @redirect_path  = url_for(:action => 'index', :schedulable_type => @schedulable.tableize, :schedulable_id => @schedulable.id, :subdomain => current_subdomain)
    end
  end
  
  # GET  /appointments/search
  # POST /appointments/search
  #  - search for an appointment by code => params[:appointment][:code]
  def search
    if request.post?
      # check confirmation code, limit search to work appointments
      @code         = params[:appointment][:code].to_s.strip
      @appointment  = Appointment.work.find_by_confirmation_code(@code)
    
      if @appointment
        # redirect to appointment show
        @redirect_path = appointment_path(@appointment, :subdomain => current_subdomain)
      else
        # show error message?
        logger.debug("*** could not find appointment #{@code}")
      end
    end

    respond_to do |format|
      format.html { @redirect_path ? redirect_to(@redirect_path) : render(:action => 'search') }
      format.js
    end
  end
    
  protected
  
  def appointment_free_time_scheduled_at(appointment)
    "#{appointment.start_at.to_s(:appt_short_month_day_year)} from #{appointment.start_at.to_s(:appt_time)} to #{appointment.end_at.to_s(:appt_time)}"
  end
  
  def build_create_redirect_path(schedulable, referer)
    # default to the schedulable's calendar show
    default_path  = url_for(:controller => 'calendar', :action => 'show', :schedulable_type => schedulable.tableize, :schedulable_id => schedulable.id, :subdomain => current_subdomain)
    
    return default_path if referer.blank?

    if referer.match(/calendar/)
      # use referer path
      referer
    else
      # use default path
      default_path
    end
  end
  
end
