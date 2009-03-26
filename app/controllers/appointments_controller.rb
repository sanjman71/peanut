class AppointmentsController < ApplicationController
  before_filter :disable_global_flash, :only => [:show, :confirmation, :work, :wait]
  after_filter  :store_location, :only => [:new]
    
  privilege_required 'update calendars', :only =>[:create], :on => :current_company
  privilege_required 'update work appointments', :only => [:work, :complete], :on => :current_company
  privilege_required 'update wait appointments', :only => [:wait], :on => :current_company
  privilege_required 'read work appointments', :only => [:index], :on => :current_company
  
  def has_privilege?(p, *args)
    case p
    when 'update calendars'
      case params[:mark_as]
      when Appointment::WORK, Appointment::WAIT
        # anyone can create work, wait appointments
        return true
      when Appointment::FREE
        # delegate to base class
        super
      else
        # delegate to base class
        super
      end
    when 'update work appointments'
      # users may update their work appointments
      authorizable  = args[0]
      user          = args[1] || current_user
      @appointment  = find_appointment_from_params
      
      return true if @appointment.work? and @appointment.customer == user
      
      # delegate to base class
      super
    when 'read work appointments'
      # users may read their work appointments
      authorizable  = args[0]
      @customer     = find_customer_from_params
      
      return true if @customer == current_user
      # delegate to base class
      super
    else
      super
    end
  end
  
  # GET /book/work/users/1/services/3/duration/60/20081231T000000
  # GET /book/wait/users/1/services/3/20090101..20090108
  def new
    if !logged_in?
      flash[:notice] = "To finalize your appointment, please log in or sign up."
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
      
      # set title
      @title                = "Book Appointment"
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

      # set title
      @title                = "Waitlist Appointment"
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
          flash[:notice]  = "Your #{@service.name} appointment has been confirmed. A confirmation email will also be sent to #{@customer.email}"
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
          flash[:notice]  = "Your are confirmed on the waitlist for a #{@service.name}.  An email will also be sent to #{@customer.email}"
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
  
  # GET /apppointments/1/work
  def work
    # @appointment has been initialized in before filter
    
    # build notes collection, most recent first 
    @note         = Note.new
    @notes        = @appointment.notes.sort_recent

    # find appointment roles
    @customer, @employee, @manager = appointment_roles(@appointment)
    
    @state        = @appointment.state
    @title        = "Appointment Details"
    
    respond_to do |format|
      format.html
    end
  end

  # GET /apppointments/1/wait
  def wait
    @appointment  = current_company.appointments.find(params[:id])
    @note         = Note.new
    
    # build notes collection, most recent first 
    @notes        = @appointment.notes.sort_recent
    
    @title        = "Waitlist Details"
    
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

  # POST /appointments/1/complete
  def complete
    # @appointment has been initialized in before filter
    
    # checkout to mark appointment as completed
    @appointment.checkout!
    
    flash[:notice]  = "Marked appointment as completed"
    
    # redirect to show appointment (based on appointment type)
    @redirect_path  = url_for(:action => @appointment.mark_as, :subdomain => current_subdomain)

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js
    end
  end
  
  # GET /appointments/1/cancel
  def cancel
    @appointment  = current_company.appointments.find(params[:id])
    @schedulable  = @appointment.schedulable
    
    if @appointment.work?
      # cancel the work appointment
      AppointmentScheduler.cancel_work_appointment(@appointment)
    elsif @appointment.wait?
      # delete the waitlist appointment
      @appointment.destroy
    end
    
    # redirect to the appointment page
    @redirect_path = work_appointment_path(@appointment)
    
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
    
  def index
    if params[:customer_id].to_s == "0"
      # /customers/0/appointments is canonicalized to /appointments; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :customer_id => nil)))
    end
    
    # find state (default to 'upcoming') and customer (default to 'anyone')
    @state      = params[:state] ? params[:state].to_s : 'upcoming'
    @customer   = params.has_key?(:customer_id) ? find_customer_from_params : User.anyone

    case @customer.id
    when 0
      # find appointments for anyone with the specified state
      @appointments = current_company.appointments.work.order_start_at.send(@state)
    else
      # find customer appointments with the specified state
      @appointments = current_company.appointments.work.customer(@customer).order_start_at.send(@state)
    end

    # find set of customers based on user role
    if company_manager?
      @customers  = [User.anyone] + current_company.authorized_users.with_role(Company.customer_role).order_by_name
    else
      @customers  = Array(current_user)
    end
    
    # set title based on customer
    @title = @customer.anyone? ? "All Appointments" : "Appointments for #{@customer.name}"
    
    respond_to do |format|
      format.html
    end
  end
  
  protected
  
  # find appointment from the params hash
  def find_appointment_from_params
    current_company.appointments.find(params[:id])
  end

  # find customer from the params hash, return nil if we can't find the customer
  def find_customer_from_params
    begin
      current_company.authorized_users.with_role(Company.customer_role).find(params[:customer_id])
    rescue
      nil
    end
  end

  # find customer from the params hash, throw exception if we can't find the customer
  def find_customer_from_params!
    current_company.authorized_users.with_role(Company.customer_role).find(params[:customer_id])
  end
  
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
