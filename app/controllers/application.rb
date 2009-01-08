# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # AuthenticatedSystem is used by restful_authentication
  include AuthenticatedSystem

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
    @current_company = Company.find_by_subdomain(current_subdomain)
    unless @current_company
      flash[:notice] = "Invalid company"
      redirect_to root_path
    end
    @subdomain = @current_company.subdomain
  end
  
end
