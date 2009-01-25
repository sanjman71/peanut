# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

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
  
  # Default layout
  layout "company"

  private
  
  def init_current_company
    # Don't look for a company if we're on the home pages
    # If we're on www.peanut.xxx then current_subdomain will be nil
    if current_subdomain
      @current_company = Company.find_by_subdomain(current_subdomain)
      
      if @current_company.blank?
        flash[:error] = "Invalid company"
        return redirect_to root_path
      end

      # initialize subdomain
      @subdomain  = @current_company.subdomain

      # initialize application time zone
      Time.zone   = @current_company.time_zone

      if session[:location_id].blank? and !@current_company.locations.empty?
        # initialize session location to company's only location
        session[:location_id] = @current_company.locations.first.id
      end
      
      @current_location = Location.find_by_id(session[:location_id]) || Location.anywhere
    end
  end

  # redirect http://[company].peanut.com/ to the company subdomain root path
  def redirect_subdomain_home_route
    return true if current_subdomain.blank? or current_subdomain == 'www'
    # its a company subdomain, redirect to subdomain root path
    redirect_to(openings_path)
    false
  end
    
end
