# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  # Make the following methods available to all helpers
  helper_method :current_subdomain, :current_company, :current_locations, :current_location, :current_privileges, 
                :manager?, :provider?, :customer?, :has_role?, :show_location?

  # AuthenticatedSystem is used by restful_authentication
  include AuthenticatedSystem

  # SSL support
  include SslRequirement
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f8d7ebb54beb33a37cef2211b595ecf7'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  # Exception notifier to send emails when we have exceptions
  # include ExceptionNotifiable

  # Helper for initializing a new user
  include UserInitializeHelper

  # Helper for re-scheduling appointments
  include AppointmentRescheduleHelper

  # Badges extentsions module
  include BadgesExtensions

  # Initialize current company and subdomain
  before_filter :init_current_company
  
  # Load and cache all user privileges on each call so we don't have to keep checking the database
  before_filter :init_current_privileges
  
  # Default layout
  layout "company"

  # check if current user has the specified role, on the optional authorizable object
  def has_role?(role_name, authorizable=nil)
    current_user.blank? ? false : current_user.has_role?(role_name, authorizable)
  end
  
  def auth_token?
    AuthToken.instance.token == params[:token].to_s
  end

  #
  # Note: current_subdomain is already defined by the subdomain_fu plugin
  #
  
  def current_company
    @current_company
  end
  
  def current_locations
    @current_locations
  end
  
  def current_location
    @current_location
  end

  # return true if the current user is a manager of the company
  def manager?
    has_role?('company manager', current_company) || has_role?('admin')
  end

  # return true if the current user is a provider of the company
  def provider?
    has_role?('company provider', current_company)
  end
  
  # returns true if the current user is a customer of the company
  def customer?
    has_role?('company customer', current_company)
  end
  
  # returns true if there is more than 1 company location
  def show_location?
    @current_locations.size > 1
  end
  
  # return the relationship(s) between the appointment and the user
  # returns a tuple with true/false values for: ['customer', 'provider', 'manager']
  def appointment_roles(appointment, user=nil)
    user      = user || current_user
    customer  = appointment.customer == user ? true : false
    provider  = appointment.provider == user ? true : false
    manager   = manager?
    [customer, provider, manager]
  end
  
  # build hash mapping days to appointment attributes that are used as css tags in calendar views
  def build_calendar_markings(appointments)
    appointments.inject(Hash.new) do |hash, appointment|
      # convert appointment start_at to utc format, and use that day as the key 
      key = appointment.start_at.utc.to_s(:appt_schedule_day)
      hash[key] ||= []
      hash[key].push(appointment.mark_as).uniq!
      
      if appointment.mark_as == Appointment::NONE
        # if the unscheduled time is not the entire day, it means there is at least one free/work appointment
        if appointment.duration != (24.hours)
          hash[key].push(Appointment::BUSY).uniq!
        end
      end
      
      hash
    end
  end

  def build_calendar_markings_from_slots(capacity_slots)
    capacity_slots.inject(Hash.new) do |hash, slot|
      key = slot.start_at.utc.to_s(:appt_schedule_day)
      hash[key] ||= []
      hash[key].push(Appointment::FREE).uniq!
      hash
    end
  end
  
  private
  
  # Initialize the current company and all related parameters (e.g. locations, time zone, ...)
  def init_current_company
    # Don't look for a company if we're on the home pages
    # If we're on www.peanut.xxx then current_subdomain will be nil
    if current_subdomain
      # find company and all associated locations
      @current_company = Company.find_by_subdomain(current_subdomain, :include => [:locations, :subscription])

      # check if its a valid company, and that its state is active
      if @current_company.blank? or @current_company.state != 'active'
        flash[:error] = "Invalid company"
        return redirect_to(root_path(:subdomain => 'www'))
      end

      # initialize subdomain
      @subdomain  = @current_company.subdomain

      # initialize application time zone
      Time.zone   = @current_company.time_zone
      
      # initialize all company locations, check locations_count before querying the database
      @current_locations = @current_company.locations_count ? @current_company.locations : []

      if session[:location_id].blank? and !@current_locations.empty?
        # initialize session location id to company's first location
        session[:location_id] = @current_locations.first.id
      end
      
      # initialize current location, default to anywhere
      @current_location = @current_locations.select { |l| l.id == session[:location_id] }.first
      @current_location = Location.anywhere if @current_location.blank?

      logger.debug("*** current_location: #{@current_location.name}, count: #{@current_locations.size}")
    end
  end

  def init_provider(options={})
    begin
      # find the provider; the send method can throw an exception
      @method   = "#{params[:provider_type].singularize}_providers"
      @provider = current_company.send(@method).find(params[:provider_id])
    rescue Exception => e
      # check for the special anyone provider
      if User.anyone.tableize == params[:provider_type] and User.anyone.id == params[:provider_id].to_i
        @provider = nil
        return @provider
      end

      if options[:default]
        @provider = options[:default]
        return @provider
      else
        logger.debug("xxx invalid provider #{params[:provider_type]}:#{params[:provider_id]}")
        redirect_to(unauthorized_path) and return
      end
    end
  end

  def init_provider_privileges
    if current_user
      @current_privileges[@provider] = current_user.privileges(@provider).collect(&:name)
    end
  end

end
