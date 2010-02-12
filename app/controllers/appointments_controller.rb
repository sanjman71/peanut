class AppointmentsController < ApplicationController
  before_filter :init_provider, :only => [:create_free, :new_block, :create_block, :new_weekly, :create_weekly, :edit_weekly,
                                          :update_weekly, :create_work, :update]
  before_filter :init_provider_privileges, :only => [:create_free, :new_block, :create_block, :new_weekly, :create_weekly, :edit_weekly,
                                                     :update_weekly, :create_work, :update]
  before_filter :init_appointment, :only => [:show]
  before_filter :init_appointment_and_provider, :only => [:cancel]
  before_filter :get_reschedule_id, :only => [:new]

  privilege_required_any  'manage appointments', :only =>[:show], :on => [:appointment, :current_company]
  privilege_required      'manage appointments', :only => [:index, :complete], :on => :current_company
  privilege_required_any  'update calendars', :only =>[:create_free, :new_block, :create_block, :new_weekly, :create_weekly, :edit_weekly,
                                                       :update_weekly, :update, :cancel],
                                              :on => [:provider, :current_company]
    

  # GET /book/work/users/1/services/3/duration/60/20081231T000000
  # GET /book/wait/users/1/services/3/20090101..20090108
  def new
    # set title
    @title = "Book Appointment"

    @provider = init_provider(:default => nil)

    if @provider.blank?
      logger.debug("[error] could not provider #{params[:provider_type]}:#{params[:provider_id]}")
      redirect_to root_path(:subdomain => current_subdomain) and return
    end

    # get appointment parameters
    @service  = current_company.services.find_by_id(params[:service_id])
    @customer = current_user

    begin

      case (@mark_as = params[:mark_as])
      when Appointment::WORK
        # build the work appointment parameters
        @duration             = params[:duration] ? params[:duration].to_i : @service.duration
        @start_at             = params[:start_at]
        @capacity             = params[:capacity].to_i if params[:capacity]

        @date_time_options    = Hash[:start_at => @start_at]
      
        @options              = Hash[:commit => false]
        @options              = @options.merge({:capacity => @capacity }) unless @capacity.blank?

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
        @appointment          = AppointmentScheduler.create_work_appointment(current_company, current_location, @provider, @service, @duration, @customer, @date_time_options, @options)

        # set appointment date, start_at and end_at times in local time
        @appt_date            = @appointment.start_at.to_s(:appt_schedule_day)
        @appt_time_start_at   = @appointment.start_at.to_s(:appt_time_army)
        @appt_time_end_at     = @appointment.end_at.to_s(:appt_time_army)

      end

    rescue AppointmentInvalid => e
      flash[:error] = e.message
      redirect_to request.referrer and return
    rescue Exception => e
      flash[:error] = e.message
      redirect_to request.referrer and return
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
    # service and mark_as may be set by create_free and create_block
    @service        ||= current_company.services.find_by_id(params[:service_id])
    @mark_as        ||= params[:mark_as]

    @customer       = User.find_by_id(params[:customer_id])

    @duration       = params[:duration] ? params[:duration].to_i : @service.duration
    @start_at       = params[:start_at]
    @end_at         = params[:end_at]
    
    @capacity       = params[:capacity].to_i if params[:capacity]

    # get appointment preferences parameters
    @preferences    = params.reject{ |k,v| !k.match(/^preferences/)}

    # track errors and appointments created
    @errors         = Hash.new
    @created        = Hash.new

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
          @options            = @options.merge({:capacity => @capacity }) unless @capacity.blank?

          # We allow force adding the appointment if the capability is requested and the user has permission
          # The caller must set params[:force].to_i != 0, e.g. 1 would be good.
          if ((!params[:force].blank?) && (params[:force].to_i != 0) &&
              ((current_user.has_privilege?('update calendars', current_company)) ||
               (current_user.has_privilege?('update calendars', @provider))))
            @options            = @options.merge({:force => true})
          end

          # create work appointment, with preferences
          @appointment        = AppointmentScheduler.create_work_appointment(current_company, current_location, @provider, @service, @duration, @customer, @date_time_options, @options)
          @appointment.update_attributes(@preferences) unless @preferences.blank?

          # set flash message
          flash[:notice]      = "Your #{@service.name} appointment has been confirmed."

          # check if its an appointment reschedule
          if has_reschedule_id?
            # cancel the old work appointment
            AppointmentScheduler.cancel_appointment(get_reschedule_appointment)
            # reset reschedule id
            reset_reschedule_id
            # reset flash message
            flash[:notice]  = "Your #{@service.name} appointment has been confirmed, and your old appointment has been canceled."
          end

          begin
            # send appointment confirmation based on preferences
            @preferences   = Hash[:customer => current_company.preferences[:work_appointment_confirmation_customer], 
                                  :manager => current_company.preferences[:work_appointment_confirmation_manager],
                                  :provider => current_company.preferences[:work_appointment_confirmation_provider]]
            @confirmations = MessageComposeAppointment.confirmations(@appointment, @preferences, {:company => current_company})
            # tell the user their confirmation email is being sent
            flash[:notice] += "<br/>A confirmation email will be sent to #{@customer.email_address}."
          rescue Exception => e
            logger.debug("[error] create appointment error sending message: #{e.message}")
            @errors[date] = "There was a problem sending a confirmation email." + e.message
          end

        when Appointment::FREE
          # build time range
          @time_range     = TimeRange.new(:day => date, :start_at => @start_at, :end_at => @end_at)
          @options        = {:time_range => @time_range}
          @options        = @options.merge({:capacity => @capacity }) unless @capacity.blank?
          # create free appointment, with preferences
          @appointment    = AppointmentScheduler.create_free_appointment(current_company, current_location, @provider, @options)
          @appointment.update_attributes(@preferences) unless @preferences.blank?

          flash[:notice]  = "Created available time"

        end
        
        logger.debug("*** created #{@appointment.mark_as} appointment")
        @created[date] = "Created #{@appointment.mark_as} appointment"
      rescue Exception => e
        logger.debug("[error] create appointment error: #{e.message}")
        logger.debug("[error] backtrace: #{e.backtrace}")
        @errors[date] = "There was a problem creating your appointment. The error message is: " + e.message
      end
    end

    # Set up our redirect.
    # If the user is a provider or manager, they are probably coming from a provider's schedule, and will redirect_back to there
    # Otherwise:
    if !logged_in?
      # The user is not logged in. They made the appointment from the openings page, and will have to log in to see their history etc.
      @redirect_path = openings_path(:subdomain => current_subdomain)
      # tell the user their account has been created
      flash[:notice] += "<br/>Your user account has been created."
      # clear session return_to to ensure the user starts clean when they login
      clear_location

    elsif current_user.has_privilege?('read calendars', current_company) || current_user.has_privilege?('read calendars', @provider)
      # If the user has the right to see company calendars, or this provider's calendar, we go there by default
      @redirect_path = calendar_show_path(:provider_type => @provider.tableize, :provider_id => @provider.id, :subdomain => current_subdomain)

    else
      # If the user is logged in but doesn't have read calendar privileges, we send them to their history page
      @redirect_path = history_index_path(:subdomain => current_subdomain)
    end

    # Set up our flash
    logger.debug("*** errors: #{@errors}") unless @errors.empty?
    logger.debug("*** created: #{@created}")

    if @errors.keys.size > 0
      # set the flash
      if @errors.keys.size == 1
        flash[:error] = "There was an error while creating your appointment</br><ul>"
      else
        flash[:error] = "There were #{@errors.keys.size} errors while creating appointments</br><ul>"
      end
      @errors.values.each do |error|
        flash[:error] += "<li>" + error + "</li>"
      end
      flash[:error] += "</ul>"
    end
    
    respond_to do |format|
      format.html { redirect_back_or_default(@redirect_path) and return }
      format.js { 
        rbdu = redirect_back_or_default_uri(@redirect_path)
        render(:update) { |page| page.redirect_to(rbdu) }
        }
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
    @service = current_company.free_service
    @mark_as = Appointment::FREE
    # check start_at, end_at values; convert 201001001T0100 to 0100
    start_match       = params[:start_at].match(/(\d+)T(\d+)/)
    end_match         = params[:end_at].match(/(\d+)T(\d+)/)
    params[:start_at] = start_match[2] unless start_match.blank?
    params[:end_at]   = end_match[2] unless end_match.blank?
    create
  end
  
  # POST /users/1/calendar/block/add
  def create_block
    @service = current_company.free_service
    @mark_as = Appointment::FREE
    create
  end

  # POST /users/1/calendar/weekly/add
  def create_weekly
    # @provider initialized in before filter

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
    @start_at       = Time.zone.parse(@dtstart)
    @end_at         = Time.zone.parse(@dtend)

    # create appointment with recurrence rule
    @options        = {:start_at => @start_at, :end_at => @end_at, :capacity => @capacity}
    @options        = @options.merge({:recur_rule => @recur_rule }) unless @recur_rule.blank?
    @error          = nil
    
    begin
      # Create the first appointment in the sequence
      @appointment  = AppointmentScheduler.create_free_appointment(current_company, current_location, @provider, @options)
    rescue Exception => e
      @error        = e.message
    end

    if !@error.blank?
      # set the flash
      flash[:error]   = @error
      @redirect_path  = build_create_redirect_path(@provider, request.referer)
    else
      flash[:notice] = 'Weekly appointment was made successfully.'
      @redirect_path  = request.referer || build_create_redirect_path(@provider, request.referer)
    end

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
      options   = params[:customer]
      @customer = User.create(options)
      if !@customer.valid?
        # not a valid customer
        flash[:error] = @customer.errors.full_messages.join("\n")
        redirect_to request.referer and return
      end
      # assign the customer id
      params[:customer_id] = @customer.id

      begin
        # send user created message
        MessageComposeUser.created(@customer.reload)
      rescue
      
      end
    end

    @mark_as = Appointment::WORK
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
    # @appointment, @provider initialized in before filter

    # Force is always true as user has already been authenticated
    force = true

    # We'll log errors, but will carry on regardless
    error = []

    # If this is (part of) a recurrence, and we've been asked to cancel the series, we do so
    if params[:series] && @appointment.recurrence?

      # We try cancel the series regardless of impact on existing appointments. 
      # First cancel the recurrence parent, so it doesn't continue to expand
      rp = @appointment.recurrence_parent

      begin
        AppointmentScheduler.cancel_appointment(rp, force)
      rescue OutOfCapacity => e
        error << e.message
      end

      # Now cancel all expanded instances after this appointment, including this one. This does not include the recurrence parent itself.
      rp.recur_instances.after_incl(self.start_at).each do |recur_instance|
        begin
          AppointmentScheduler.cancel_appointment(recur_instance, force)
        rescue OutOfCapacity => e
          error << e.message
        end
      end

      if error.empty?
        flash[:notice] = "We have canceled this and all future availability in this series. No more will be created."
      else
        flash[:error] = "We had issues canceling #{error.size} availability appointments in this series. We have canceled all possible availability."
      end
    
      #
      # Not using this code yet - deals with recurrences
      #

      # elsif @appointment.recurrence_parent?
      # 
      #   # cancel the recurrence, including all future instances of it
      #   begin
      #     AppointmentScheduler.cancel_appointment(@appointment, force)
      #   rescue OutOfCapacity => e
      #     error << e.message
      #   end
      #   
      #   # Now cancel all expanded instances after this appointment, including this one. This does not include the recurrence parent itself.
      #   @appointment.recur_instances.future.each do |recur_instance|
      #     begin
      #       AppointmentScheduler.cancel_appointment(recur_instance, force)
      #     rescue OutOfCapacity => e
      #       error << e.message
      #     end
      #   end
      # 
      #   if error.empty?
      #     flash[:notice] = "We have canceled all availability in this series. No more will be created"
      #   else
      #     flash[:error] = "We had issues canceling all availability in this series. We have canceled all possible availability."
      #   end

    else

      # cancel the appointment
      begin
        AppointmentScheduler.cancel_appointment(@appointment, force)
      rescue OutOfCapacity => e
        error << e.message
      end
      
      # set flash
      appt_text = ( (@appointment.mark_as == Appointment::WORK) ? "appointment" : "availability" )
      if error.empty?
        flash[:notice] = "We have canceled this #{appt_text}."
      else
        flash[:notice] = "We had a problem canceling this #{appt_text} - #{error[0]}."
      end

    end

    # redirect to referer; default to appointment path
    @redirect_path = request.referer || appointment_path(@appointment)

    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end

  # PUT /appointments/1
  def update
    # @provider initialized in before filter

    @appointment          = current_company.appointments.find(params[:id])

    # Update appointment fields
    @service              = init_service(:default => (@appointment.free? ? @appointment.company.free_service : nil))
    @customer             = User.find_by_id(params[:customer_id])

    @appointment.provider = @provider
    @appointment.service  = @service
    @appointment.customer = @customer
    @appointment.start_at = params[:start_at]
    if !params[:duration].blank?
      # build end time using start time and duration
      @appointment.end_at = @appointment.start_at + params[:duration].to_i
    else
      # use specified end time
      @appointment.end_at = params[:end_at]
    end

    # Force is always true as user has already been authenticated
    @appointment.force = true

    if @appointment.save
      # Set up our redirect path
      if !logged_in?
        # The user is not logged in. They made the appointment from the openings page, and will have to log in to see their history etc.
        @redirect_path = openings_path
        # tell the user their account has been created
        # clear session return_to to ensure the user starts clean when they login
        clear_location
      else
        # apointment updates are done in dialogs, so redirect to the referer page
        @redirect_path = request.referer
      end

      if @appointment.free?
        flash[:notice] = "Your available time has been updated"
      else
        flash[:notice] = "Your appointment has been updated"
      end

      respond_to do |format|
        format.html { redirect_to(@redirect_path) }
        format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
      end
    else
      flash[:error] = "There was a problem updating your appointment<br/>" + @appointment.errors.full_messages.join("<br/>")

      # apointment updates are done in dialogs, so redirect to the referer page
      @redirect_path = request.referer

      respond_to do |format|
        format.html { redirect_to(@redirect_path) }
        format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
      end
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
        if (current_company.appointments.work.future.not_canceled.in_recurrence(@appointment.id).count == 0)
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
            @redirect_path = history_index_path
          end

        else
          # record the conflicting work appointments so we can show them
          @conflicts = current_company.appointments.work.future.not_canceled.in_recurrence(@appointment.id)
          flash[:error] = "You cannot remove this recurring series as there are some conflicting work appointments"
        end

      else

        # We're only removing this instance
        if @appointment.work_conflicts.count != 0
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
            @redirect_path = history_index_path
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
        @redirect_path = history_index_path
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
    
    # find state (default to 'all') and customer (default to 'anyone')
    @state      = params[:state] ? params[:state].to_s : 'all'
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
    @appointment = current_company.appointments.find(params[:id])
  end

  def init_appointment_and_provider
    init_appointment
    @provider = @appointment.andand.provider
  end

  # find customer from the params hash, return nil if we can't find the customer
  def find_customer_from_params
    begin
      current_company.authorized_users.with_role(Company.customer_role).find(params[:customer_id])
    rescue
      nil
    end
  end

  def appointment_free_time_scheduled_at(appointment)
    "#{appointment.start_at.to_s(:appt_short_month_day_year)} from #{appointment.start_at.to_s(:appt_time)} to #{appointment.end_at.to_s(:appt_time)}"
  end

  def build_create_redirect_path(provider, referer)
    # default to the provider's calendar show
    calendar_show_path = url_for(:controller => 'calendar', :action => 'show', :provider_type => provider.tableize, :provider_id => provider.id, :subdomain => current_subdomain)
  end
  
end
