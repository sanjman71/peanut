class ApplicationController < ActionController::Base 

  # These before filters are not necessary, but are used to mirror the real app
  before_filter :init_current_company
  before_filter :init_current_privileges
  
  # check user privileges against the pre-loaded memory collection instead of using the database
  def has_privilege?(p, *args)
    authorizable  = args[0]
    user          = args[1] || current_user
    logger.debug("*** checking privilege #{p}, on authorizable #{authorizable ? authorizable.name : ""}, for user #{user ? user.name : ""}")
    return false if current_privileges.blank?
    return current_privileges.include?(p)
  end

  # return true if the current user is a company manager
  def company_manager?
    current_user.has_role?('company manager', current_company) || current_user.has_role?('admin')
  end

  # these flash methods are needed for the functional tests
  
  def global_flash?
    @global_flash = true if @global_flash.nil?
    return @global_flash
  end
  
  def disable_global_flash
    @global_flash = false
  end

  private
  
  def init_current_company
    @current_company = nil
  end
  
  def init_current_privileges
    @current_privileges = []
  end
  
end
