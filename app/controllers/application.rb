# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  # Make the following methods available to all helpers
  helper_method :current_subdomain, :current_company, :current_locations, :current_location, :current_privileges

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

      logger.debug("*** current_location: #{@current_location.name}")
    end
  end
    
  def init_current_privileges
    if logged_in?
      if @current_company
        # load privileges on current company (includes privileges on no authorizable object)
        @current_privileges = current_user.privileges(@current_company).collect { |p| p.name }
      else
        # load privileges without an authorizable object
        @current_privileges = current_user.privileges.collect { |p| p.name }
      end
    else
      @current_privileges = []
    end
  end
end
