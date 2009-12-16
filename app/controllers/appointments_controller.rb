class AppointmentsController < ApplicationController
  before_filter :init_provider, :only => [:create_free, :new_block, :create_block, :new_weekly, :create_weekly, :edit_weekly, :update_weekly,
                                          :create_work]
  before_filter :init_provider_privileges, :only => [:create_free, :new_block, :create_block, :new_weekly, :create_weekly, :edit_weekly, :update_weekly,
                                                     :create_work]
  before_filter :init_appointment, :only => [:show]
  before_filter :get_reschedule_id, :only => [:new]

  privilege_required_any  'manage appointments', :only =>[:show], :on => [:appointment, :current_company]
  privilege_required_any  'update calendars', :only =>[:create_free, :new_block, :create_block, :new_weekly, :create_weekly, :edit_weekly, :update_weekly],
                                              :on => [:provider, :current_company]
    
  privilege_required      'manage appointments', :only => [:index, :complete], :on => :current_company
  
  # GET /book/work/users/1/services/3/duration/60/20081231T000000
  # GET /book/wait/users/1/services/3/20090101..20090108
  def new
    @provider = init_provider(:default => nil)

    if @provider.blank?
      logger.debug("[error] could not provider #{params[:provider_type]}:#{params[:provider_id]}")
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
        @customer_signup    = :all
        # set return_to url in case user uses rpx to login and needs to be redirected back
        session[:return_to] = request.url
      else
        @customer_signup    = nil
      end

      # build the work appointment without committing the changes
      @appointment          = AppointmentScheduler.create_work_appointment(current_company, @provider, @service, @duration, @customer, @date_time_options, @options)

      # set appointment date, start_at and end_at times in local time
      @appt_date            = @appointment.start_at.to_s(:appt_schedule_day)
      @appt_time_start_at   = @appointment.start_at.to_s(:appt_time_army)
      @appt_time_end_at     = @appointment.end_at.to_s(:appt_time_army)

      # set title
      @title                = "Book Appointment"
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
    
    # initialize dates collection
    case
    when params[:dates]
      @dates = Array(params[:dates])
    when params[:date]
      @dates = Array(params[:date])
    else
      # defaults to start_at date
      @dates = Array[@start_at]
    end

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
          flash[:notice] += "<br/>A confirmation email will be sent to #{@customer.email_address}."
          
          if !logged_in?
            @redirect_path = openings_path
            # tell the user their account has been created
            flash[:notice] += "<br/>Your user account has been created."
            # clear session return_to to ensure the user starts clean when they login
            session[:return_to] = nil
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
          @appointment    = AppointmentScheduler.create_free_appointment(current_company, @provider, @options)
          # set redirect path
          @redirect_path  = request.referer
          flash[:notice]  = "Created available time"
        end
        
        logger.debug("*** created #{@appointment.mark_as} appointment")
        @created[date] = "Created #{@appointment.mark_as} appointment"
      rescue Exception => e
        logger.debug("[error] create appointment error: #{e.message}")
        logger.debug("[error] backtrace: #{e.backtrace}")
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

  # GET /users/1/calendar/block/edit
  def new_block
    # @provider initialized in before_filter
    
    # if params[:provider_type].blank? or params[:provider_id].blank?
    #   # no provider was specified, redirect to the company's first provider
    #   provider = current_company.providers.first
    #   redirect_to url_for(params.update(:subdomain => current_subdomain, :provider_type => provider.tableize, :provider_id => provider.id)) and return
    # end
        
    # build list of providers to allow the scheduled to be adjusted by resource
    @providers = current_company.providers
    
    # initialize daterange, start calendar today, end on saturday to make it all line up nicely
    @daterange = DateRange.parse_when('next 4 weeks', :end_on => ((current_company.preferences[:start_wday].to_i - 1) % 7))
        
    # find free work appointments
    @free_work_appts    = AppointmentScheduler.find_free_work_appointments(current_company, current_location, @provider, @daterange)

    # group appointments by day
    @free_work_appts_by_day = @free_work_appts.group_by { |appt| appt.start_at.utc.beginning_of_day }
    
    # build calendar markings from free appointments
    @calendar_markings  = build_calendar_markings(@free_work_appts)
    
    # build time of day collection
    # TODO xxx - need a better way of mapping these times to start, end hours
    @tod        = ['morning', 'afternoon']
    @tod_start  = 'morning'
    @tod_end    = 'afternoon'
    
    @free_service = current_company.free_service
    
    respond_to do |format|
      format.html { render "edit_block.html"}
    end
  end
  
  # GET /users/1/calendar/weekly/new
  def new_weekly
    # @provider initialize in before_filter
    
    if params[:provider_type].blank? or params[:provider_id].blank?
      # no provider was specified, redirect to the company's first provider
      provider = current_company.providers.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :provider_type => provider.tableize, :provider_id => provider.id)) and return
    end

    # build list of providers to allow the scheduled to be adjusted by resource
    @providers = current_company.providers

    # initialize daterange. Just used to show days of week.
    @daterange = DateRange.parse_when('this week')

    # initialize calendar markings to empty
    @calendar_markings  = Hash.new

    # Initialize the appointment
    @appointment = Appointment.new

    respond_to do |format|
      format.html { render "edit_weekly.html"}
    end
  end
  
  # GET /users/1/calendar/weekly/:id/edit
  def edit_weekly
    # @provider initialize in before_filter
    
    if params[:provider_type].blank? or params[:provider_id].blank?
      # no provider was specified, redirect to the company's first provider
      flash[:error] = "No provider was specified"
      provider = current_company.providers.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :provider_type => provider.tableize, :provider_id => provider.id)) and return
    end

    @appointment = Appointment.find(params[:id])
    if (@appointment.blank? || @appointment.recur_rule.blank?)
      flash[:error] = "Recurring appointment wasn't found"
      redirect_to url_for(params.update(:subdomain => current_subdomain, :provider_type => @provider.tableize, :provider_id => @provider.id)) and return
    end
    
    # initialize daterange. Just used to show days of week.
    @daterange = DateRange.parse_when('this week')

    # initialize calendar markings to empty
    @calendar_markings  = Hash.new

    respond_to do |format|
      format.html
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
    @dend         = params[:dend].to_s
    @tend         = params[:tend].to_s
    @until        = params[:until].to_s

    # ensure capacity is at least 1
    @capacity     = params[:capacity].to_i || 1
    @capacity     = 1 if @capacity <= 0

    # build recurrence rule from rule components
    tokens        = ["FREQ=#{@freq}", "BYDAY=#{@byday}"]

    unless @until.blank?
      tokens.push("UNTIL=#{@until}T000000Z")
    end

    @recur_rule   = tokens.join(";")

    # build dtstart and dtend
    @dtstart      = "#{@dstart}T#{@tstart}"
    if (@dend.blank?)
      @dtend        = "#{@dstart}T#{@tend}"
    else
      @dtend        = "#{@dend}T#{@tend}"
    end

    # build start_at and end_at times
    @start_at_utc = Time.zone.parse(@dtstart).utc
    @end_at_utc   = Time.zone.parse(@dtend).utc

    # create appointment with recurrence rule
    @appointment  = current_company.appointments.create(:company => current_company, :provider => @provider, :service => @free_service,
                                                        :start_at => @start_at_utc, :end_at => @end_at_utc, :mark_as => Appointment::FREE,
                                                        :recur_rule => @recur_rule, :capacity => @capacity)

    # build redirect path
    @redirect_path  = build_create_redirect_path(@provider, request.referer)

    respond_to do |format|
      if @appointment.valid?
        flash[:notice] = 'Weekly appointment was made successfully.'
        format.html { redirect_to(@redirect_path) and return }
        format.js
      else
        flash[:notice] = 'Problem making weekly appointment.'
        format.html { render :template => "calendar/edit_weekly.html" }
        format.js
      end
    end

  end

  # POST /book/work/users/7/services/4/60/20090901T060000
  # anyone can create work appointments
  def create_work
    # check for a customer signup
    if params[:customer]
      # create new user, assign a random password
      options   = params[:customer]
      @customer = User.create_or_reset(options)
      if !@customer.valid?
        # not a valid customer
        flash[:error] = @customer.errors.full_messages.join("\n")
        redirect_to request.referer and return
      end
      # assign the customer id
      params[:customer_id] = @customer.id
    end
    
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

    # find appointment roles
    @customer, @owner, @manager = appointment_roles(@appointment)

    case @appointment.mark_as
    when Appointment::WORK
      @title = "Appointment Details"
    when Appointment::FREE
      @title = "Free Time Details"
    end

    # Get list of instances if this is a recurring available appointment
    if @appointment.mark_as == Appointment::FREE && @appointment.recurrence?
      @instances_by_day = @appointment.recurrence_parent.recur_instances.future.group_by { |appt| appt.start_at.beginning_of_day }
    end

    # show invoices for completed appointments
    # @invoice      = @appointment.invoice
    # @services     = current_company.services.work.all
    # @products     = current_company.products.instock
    # @mode         = :r

    # build notes collection, most recent first 
    @note   = Note.new
    @notes  = @appointment.notes.sort_recent

    # set back link
    @back   = request.referer

    respond_to do |format|
      format.html { render(:action => @appointment.mark_as) }
    end
  end
  
  # GET /appointments/1/approve
  def approve
    flash[:notice] = "Todo: appointment approval process"
    redirect_to(request.referer) and return
  end
  
  # GET /appointments/1/complete
  def complete
    @appointment = current_company.appointments.find(params[:id])
    @appointment.complete!

    flash[:notice] = "Marked appointment as completed"
    redirect_to(request.referer) and return
  end

  # GET /appointments/1/noshow
  def noshow
    @appointment = current_company.appointments.find(params[:id])
    @appointment.noshow!

    flash[:notice] = "Marked appointment as noshow"
    redirect_to(request.referer) and return
  end

  # GET /appointments/1/cancel
  def cancel
    @appointment = current_company.appointments.find(params[:id])

    case @appointment.mark_as
    when Appointment::WORK
      # cancel the work appointment
      AppointmentScheduler.cancel_work_appointment(@appointment)
    end

    # redirect to the appointment page
    @redirect_path = appointment_path(@appointment)

    # set flash
    flash[:notice] = "Marked appointment as canceled"

    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js
    end
  end

  # DELETE /appointments/1
  def destroy
    @appointment  = current_company.appointments.find(params[:id])

    @provider    = @appointment.provider
    
    # If this is a free appointment, we need to ensure it doesn't have any attached work appointments before destroying it.
    if @appointment.mark_as == Appointment::FREE

      # If we are being asked to remove all future free appointments in a recurrence then we need to iterate through all 
      # future recurrence children determining whether or not we can remove them all.
      if params[:series] && @appointment.recurrence?
        @conflicts = []
        # Find all conflicting work appointments in this series of free appointments
        # Start with the parents
        if @appointment.recurrence_parent.work_appointments.not_canceled.count > 0
          @conflicts << @appointment.recurrence_parent
        end
        # And continue with all the instances
        @appointment.recurrence_parent.recur_instances.future.each do |appointment|
          if appointment.work_appointments.not_canceled.count > 0
            @conflicts << appointment
          end
        end
        
        if @conflicts.empty?
          # Disable the recurrence parent. For now we remove the recurrence rule
          # Note - important to do it like this - clearing recur_rule means that @appointment.recurrence_parent will be nil when we save if this is
          # the recurrence_parent
          rp = @appointment.recurrence_parent
          rp.recur_rule = nil
          rp.save

          # Now destroy all future instances. This does not include the recurrence parent itself.
          rp.recur_instances.future.each do |appointment|
            appointment.destroy
          end
          # Finally destroy the recurrence parent if it exists in the future
          if rp.start_at > Time.zone.now
            rp.destroy
          end
          flash[:notice] = "All future members of this recurring series have been removed and no more will be created"

          # Make sure we don't redirect to an appointment we just destroyed 
          if request.referrer && !(params[:series]) && !(request.referrer =~ /#{appointment_path(params[:id])}$/)
            @redirect_path = request.referrer
          elsif current_user.has_privilege?('read calendars', current_company) || current_user.has_privilege?('read calendars', @provider)
            @redirect_path = calendar_show_path(:provider_type => @provider.tableize, :provider_id => @provider.id, :subdomain => current_subdomain)
          else
            @redirect_path = history_path
          end

        else
          flash[:error] = "You cannot remove this recurring series as there are some conflicting work appointments"
        end

      else

        # We're only removing this instance
        if @appointment.work_appointments.not_canceled.count != 0
          flash[:error] = "You cannot remove this available time until all existing appointments in it have been cancelled or removed"
        else

          @appointment.destroy

          # set flash
          flash[:notice] = "Deleted available time"
          logger.debug("*** deleted appointment #{@appointment.id}")

          # Make sure we don't redirect to an appointment we just destroyed 
          if request.referrer && !(params[:series]) && !(request.referrer =~ /#{appointment_path(params[:id])}$/)
            @redirect_path = request.referrer
          elsif current_user.has_privilege?('read calendars', current_company) || current_user.has_privilege?('read calendars', @provider)
            @redirect_path = calendar_show_path(:provider_type => @provider.tableize, :provider_id => @provider.id, :subdomain => current_subdomain)
          else
            @redirect_path = history_path
          end

        end
      end

      # Work appointments are destroyed automatically
    else
      @appointment.destroy

      flash[:notice] = "Deleted appointment"

      # Deleting a work appointment. There are no recurring appointments in this case, thought we'll leave the check in for the future..
      if request.referrer && !(params[:series]) && !(request.referrer =~ /#{appointment_path(params[:id])}$/)
        @redirect_path = request.referrer
      elsif current_user.has_privilege?('read calendars', current_company) || current_user.has_privilege?('read calendars', @provider)
        @redirect_path = calendar_show_path(:provider_type => @provider.tableize, :provider_id => @provider.id, :subdomain => current_subdomain)
      else
        @redirect_path = history_path
      end

      logger.debug("*** deleted appointment #{@appointment.id}")

    end

    respond_to do |format|
      format.html { @redirect_path ? redirect_to(@redirect_path) : render(:action => 'index') }
      format.js
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
    
    # find state (default to 'confirmed') and customer (default to 'anyone')
    @state      = params[:state] ? params[:state].to_s : 'confirmed'
    @customer   = params.has_key?(:customer_id) ? find_customer_from_params : User.anyone

    case @customer.id
    when 0
      # find work appointments for anyone with the specified state
      @appointments = current_company.appointments.work.order_start_at.send(@state)
      @anyone       = true
    else
      # find customer work appointments with the specified state
      @appointments = current_company.appointments.work.customer(@customer).order_start_at.send(@state)
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
