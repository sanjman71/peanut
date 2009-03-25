# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  # Make the following methods available to all helpers
  helper_method :current_subdomain, :current_company, :current_locations, :current_location, :current_privileges, :company_manager?, 
                :show_location?, :global_flash?

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
  include ExceptionNotifiable
  
  # Initialize current company and subdomain
  before_filter :init_current_company
  
  # Load and cache all user privileges on each call so we don't have to keep checking the database
  before_filter :init_current_privileges
  
  # Default layout
  layout "company"

  # check user privileges against the pre-loaded memory collection instead of using the database
  def has_privilege?(p, *args)
    authorizable  = args[0]
    user          = args[1] || current_user
    logger.debug("*** checking privilege #{p}, on authorizable #{authorizable ? authorizable.name : ""}, for user #{user ? user.name : ""}")
    return false if current_privileges.blank?
    return current_privileges.include?(p)
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
  
  def current_privileges
    @current_privileges ||= []
  end
  
  # return true if the current user is a company manager
  def company_manager?
    current_user.has_role?('company manager', current_company) || current_user.has_role?('admin')
  end
  
  # returns true if there is more than 1 company location
  def show_location?
    @current_locations.size > 1
  end
  
  # controls whether the flash may be displayed in the header, defaults to true
  def global_flash?
    @global_flash = true if @global_flash.nil?
    return @global_flash
  end
  
  def disable_global_flash
    @global_flash = false
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
        if appointment.duration != 24 * 60
          hash[key].push(Appointment::BUSY).uniq!
        end
      end
      
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
      @current_company = Company.find_by_subdomain(current_subdomain, :include => :locations)
      
      if @current_company.blank?
        flash[:error] = "Invalid company"
        return redirect_to(root_path)
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
    
  def init_current_privileges
    if logged_in?
      if @current_company
        # load privileges on current company (includes privileges on no authorizable object)
        @current_privileges = current_user.privileges(@current_company).collect(&:name)
      else
        # load privileges without an authorizable object
        @current_privileges = current_user.privileges.collect(&:name)
      end
    else
      @current_privileges = []
    end
  end
end
