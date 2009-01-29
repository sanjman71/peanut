#require 'controllers/application'

class ApplicationController < ActionController::Base 

  # Initialize current company and subdomain
  before_filter :init_current_company
  
  # check user privileges against the pre-loaded memory collection instead of using the database
  def has_privilege?(p, *args)
    authorizable  = args[0]
    user          = args[1] || current_user
    logger.debug("*** checking privilege #{p}, on authorizable #{authorizable ? authorizable.name : ""}, for user #{user ? user.name : ""}")
    return has_stubbed_privilege?(p)
  end

  # this method should be stubbed by test cases
  def has_stubbed_privilege?(p)
    return false
  end
  
  private
  
  def init_current_company
    # use a default subdomain in the test environment
    @current_company = Company.find_by_subdomain("company1")
  end
  
end
