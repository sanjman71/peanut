class AppointmentsController < ApplicationController
  before_filter :init_provider, :only => [:create_free, :create_block, :create_weekly, :create_work, :create_wait]
  before_filter :init_provider_privileges, :only => [:create_free, :create_block, :create_weekly, :create_work, :create_wait]
  before_filter :init_appointment, :only => [:show]
  before_filter :get_reschedule_id, :only => [:new]
  after_filter  :store_location, :only => [:new]

  privilege_required_any  'manage appointments', :only =>[:show], :on => [:appointment, :current_company]
  privilege_required_any  'update calendars', :only =>[:create_free, :create_block, :create_weekly], :on => [:provider, :current_company]
    
  privilege_required      'read work appointments', :only => [:index], :on => :current_company
  privilege_required      'update work appointments', :only => [:complete], :on => :current_company
  # privilege_required      'read %s appointments', :only => [:show], :on => :current_company

  def has_privilege?(p, authorizable=nil, user=nil)
    case p
    # when 'update calendars'
    #   case params[:mark_as]
    #   when Appointment::WORK, Appointment::WAIT
    #     # anyone can create work, wait appointments
    #     return true
    #   when Appointment::FREE
    #     # delegate to base class
    #     super
    #   else
    #     # delegate to base class
    #     super
    #   end
    when 'read work appointments'
      # users may read their work appointments
      @customer = find_customer_from_params
      
      return true if @customer == user
      # delegate to base class
      super
    when 'read %s appointments'
      # users may read their work/wait appointments
      @appointment  = find_appointment_from_params
      
      return false if @appointment.blank?
      return true if @appointment.customer == user
      
      # set permission based on appointment type, and delegate to base class
      p = p % @appointment.mark_as
      super
    else
      super
    end
  end
  
  # GET /book/work/users/1/services/3/duration/60/20081231T000000
  # GET /book/wait/users/1/services/3/20090101..20090108
  def new
    # if !logged_in?
    #   flash[:notice] = "To finalize your appointment, please log in or sign up."
    #   redirect_to(login_path) and return
    # end

    @provider = init_provider(:default => nil)

    if @provider.blank?
      logger.debug("xxx could not provider #{params[:provider_type]}:#{params[:provider_id]}")
      redirect_to root_path(:subdomain => current_subdomain) and return
    end

    # get appointment parameters
    @service  = current_company.services.find_by_id(params[:service_id])
    @customer = current_user
    
    case (@mark_as = params[:mark_as])
    when Appointment::WORK
      # build the work appointment parameters
      @duration             = params[:duration].to_i if params[:duration]
      @start_at             = params[:start_at]
      @date_time_options    = Hash[:start_at => @start_at]
      @options              = Hash[:commit => false]

      # allow customer to be created during this process
      if @customer.blank?
        @customer           = User.anyone
        @customer_signup    = true
      end

      # build the work appointment without committing the changes
      @appointment          = AppointmentScheduler.create_work_appointment(current_company, @provider, @service, @duration, @customer, @date_time_options, @options)

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
      
      # build the waitlist appointment without committing the changes
      @appointment          = AppointmentScheduler.create_waitlist_appointment(current_company, @provider, @service, @customer, @options, :commit => false)
      
      # default provider is 'anyone' for display purposes
      @provider             = User.anyone if @provider.blank?
      
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
    # @provider initialized in before filter
    
    if params[:action] == 'create'
      # not allowed to directly call 'create'
      redirect_to unauthorized_path and return
    end

    # get appointment parameters
    @service        = current_company.services.find_by_id(params[:service_id])
    @customer       = User.find_by_id(params[:customer_id])

    @mark_as        = params[:mark_as]
    @duration       = params[:duration].to_i if params[:duration]
    @start_at       = params[:start_at]
    @end_at         = params[:end_at]

    # track errors and appointments created
    @errors         = Hash.new
    @created        = Hash.new

    # set default redirect path
    @redirect_path  = request.referer
    
    # iterator over the specified dates, if provided, or use single start_at date
    @dates          = params[:dates] ?  Array(params[:dates]) : Array[@start_at]
    
    @dates.each do |date|
      begin
        case @mark_as
        when Appointment::WORK
          # build time range
          # @time_range     = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)
          # @options        = {:time_range => @time_range}
          @date_time_options  = Hash[:start_at => @start_at]
          @options            = Hash[:commit => true]
          # create work appointment
          @appointment        = AppointmentScheduler.create_work_appointment(current_company, @provider, @service, @duration, @customer, @date_time_options, @options)
          # set redirect path
          @redirect_path      = appointment_path(@appointment, :subdomain => current_subdomain)
          # set flash message
          flash[:notice]      = "Your #{@service.name} appointment has been confirmed."

          # check if its an appointment reschedule
          if has_reschedule_id?
            # cancel the old work appointment
            AppointmentScheduler.cancel_work_appointment(get_reschedule_appointment)
            # reset reschedule id
            reset_reschedule_id
            # reset flash message
            flash[:notice]  = "Your #{@service.name} appointment has been confirmed, and your old appointment has been canceled."
          end
          
          # tell the user their confirmation email is being sent
          flash[:notice] += "<br/>A confirmation email will be sent to #{@customer.email_address}"
          
          if !logged_in?
            @redirect_path = openings_path
            # tell the user their account has been created
            flash[:notice] += "<br/>Your user account has been created and your password will be sent to #{@customer.email_address}"
          else
            @redirect_path = history_index_path
          end
          
          # # create log_entry
          # current_company.log_entries.create(:user_id => current_user.id, :etype => LogEntry::INFORMATIONAL, :loggable => @appointment,
          #                               :message_id => LogEntriesHelper::LOG_ENTRY_MESSAGE_IDS[:appointment_confirmation],
          #                               :customer => @appointment.customer)
        when Appointment::FREE
          # build time range
          @time_range     = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)
          @options        = {:time_range => @time_range}
          # create free appointment
          @appointment    = AppointmentScheduler.create_free_appointment(current_company, @provider, @service, @options)
          # set redirect path
          @redirect_path  = request.referer
          flash[:notice]  = "Created available time"
        when Appointment::WAIT
          # build date range
          @daterange      = DateRange.parse_range(@start_at, @end_at, :inclusive => true)
          @options        = {:start_at => @daterange.start_at, :end_at => @daterange.end_at}
          # create waitlist appointment
          @appointment    = AppointmentScheduler.create_waitlist_appointment(current_company, @provider, @service, @customer, @options, :commit => true)
          # set redirect path
          @redirect_path  = appointment_path(@appointment, :subdomain => current_subdomain)
          flash[:notice]  = "Your are confirmed on the waitlist for a #{@service.name}.  An email will also be sent to #{@customer.email}"
          # # create log_entry
          # current_company.log_entries.create(:user_id => current_user.id, :etype => LogEntry::INFORMATIONAL, :loggable => @appointment,
          #                               :message_id => LogEntriesHelper::LOG_ENTRY_MESSAGE_IDS[:added_to_waitlist],
          #                               :customer => @appointment.customer)
        end
        
        logger.debug("*** created #{@appointment.mark_as} appointment")
        @created[date] = "Created #{@appointment.mark_as} appointment"
      rescue Exception => e
        logger.debug("xxx create appointment error: #{e.message}")
        @errors[date] = e.message
      end
    end

    logger.debug("*** errors: #{@errors}") unless @errors.empty?
    logger.debug("*** created: #{@created}")

    if @errors.keys.size > 0
      # set the flash
      flash[:error]   = "There were #{@errors.keys.size} errors creating appointments"
      @redirect_path  = build_create_redirect_path(@provider, request.referer)
    else
      @redirect_path  = @redirect_path || build_create_redirect_path(@provider, request.referer)
    end
    
    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end
  
  # POST /users/1/calendar/free/add
  def create_free
    create
  end
  
  # POST /users/1/calendar/block/add
  def create_block
    create
  end

  # POST /users/1/calendar/weekly/add
  def create_weekly
    # @provider initialized in before filter
    
    @free_service = current_company.free_service

    # get recurrence parameters
    @freq         = params[:freq].to_s.upcase
    @byday        = params[:byday].to_s.upcase
    @dstart       = params[:dstart].to_s
    @tstart       = params[:tstart].to_s
    @tend         = params[:tend].to_s
    @until        = params[:until].to_s
    
    @capacity     = params[:capacity].to_i

    # build recurrence rule from rule components
    tokens        = ["FREQ=#{@freq}", "BYDAY=#{@byday}"]

    unless @until.blank?
      tokens.push("UNTIL=#{@until}T000000Z")
    end

    @recur_rule   = tokens.join(";")

    # build dtstart and dtend
    @dtstart      = "#{@dstart}T#{@tstart}"
    @dtend        = "#{@dstart}T#{@tend}"

    # build start_at and end_at times
    @start_at_utc = Time.parse(@dtstart).utc
    @end_at_utc   = Time.parse(@dtend).utc

    # create appointment with recurrence rule
    @appointment  = current_company.appointments.create(:company => current_company, :provider => @provider, :service => @free_service,
                                                        :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => Appointment::FREE,
                                                        :recur_rule => @recur_rule, :capacity => @capacity)

    # build redirect path
    @redirect_path  = build_create_redirect_path(@provider, request.referer)

    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js
    end
  end

  # POST /book/work/users/7/services/4/60/20090901T060000
  # anyone can create work appointments
  def create_work
    # check for a customer signup
    if params[:customer]
      # create new user, assign a random password
      options   = Hash[:name => params[:customer][:name], :email => params[:customer][:email], :password => :random]
      @customer = User.create_or_reset(options)
      # assign the customer id
      params[:customer_id] = @customer.id
    end
    
    create
  end

  # anyone can create wait appointments
  def create_wait
    create
  end

  # GET /appointments/1/reschedule
  def reschedule
    @appointment  = current_company.appointments.find(params[:id])

    if request.post?
      # start the re-schedule process
      logger.debug("*** starting the re-schedule process")
      set_reschedule_id(@appointment)
      @redirect_path = url_for(:controller => 'openings', :action => 'index', :type => 'reschedule', :subdomain => current_subdomain)
    end
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  # GET /appointments/1
  def show
    # @appointment has been initialized in before filter
    
    # set back link
    @back   = request.referer
    
    # find appointment roles
    @customer, @owner, @manager = appointment_roles(@appointment)
    
    case @appointment.mark_as
    when Appointment::WORK
      @title = "Appointment Details"
    when Appointment::WAIT
      @title = "Waitlist Details"
    end
    
    # show invoices for completed appointments
    # @invoice      = @appointment.invoice
    # @services     = current_company.services.work.all
    # @products     = current_company.products.instock
    # @mode         = :r
    
    # build notes collection, most recent first 
    @note         = Note.new
    @notes        = @appointment.notes.sort_recent

    respond_to do |format|
      format.html { render(:action => @appointment.mark_as) }
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
    @provider  = @appointment.provider
    
    case @appointment.mark_as
    when  Appointment::WORK
      # cancel the work appointment
      AppointmentScheduler.cancel_work_appointment(@appointment)
      message_id = LogEntriesHelper::LOG_ENTRY_MESSAGE_IDS[:appointment_canceled]
    when Appointment::WAIT
      # cancel the wait appointment
      AppointmentScheduler.cancel_wait_appointment(@appointment)
      message_id = LogEntriesHelper::LOG_ENTRY_MESSAGE_IDS[:waitlist_canceled]
    end

    # redirect to the appointment page
    @redirect_path = appointment_path(@appointment, :subdomain => current_subdomain)
    
    # create log_entry
    current_company.log_entries.create(:user_id => current_user.id, :etype => LogEntry::INFORMATIONAL, :loggable => @appointment,
                                  :message_id => message_id, :customer => @appointment.customer)

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
      # redirect to provider appointment path
      @provider    = @appointment.provider
      @redirect_path  = url_for(:action => 'index', :provider_type => @provider.tableize, :provider_id => @provider.id, :subdomain => current_subdomain)
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
      # find work, wait appointments for anyone with the specified state
      @appointments = current_company.appointments.wait_work.order_start_at.send(@state)
      @anyone       = true
    else
      # find customer work, wait appointments with the specified state
      @appointments = current_company.appointments.wait_work.customer(@customer).order_start_at.send(@state)
      @anyone       = false
    end

    # group appointments by customer
    @appointments_by_customer = @appointments.group_by { |appt| appt.customer }

    # company managers can see all customers; othwerwise the user can only see their own appointments
    if manager?
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

  def init_appointment
    @appointment = Appointment.find(params[:id])
  end
  
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

  def build_create_redirect_path(provider, referer)
    # default to the provider's calendar show
    calendar_show_path = url_for(:controller => 'calendar', :action => 'show', :provider_type => provider.tableize, :provider_id => provider.id, :subdomain => current_subdomain)
  end
  
end
