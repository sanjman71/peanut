module UserInitializeHelper
  
  protected
  
  def user_initialize(company, user, role, creator, invitation = nil)
    role_string = nil
    case role
    when 'company provider'
      # add the user as a company provider
      company.providers.push(user)
      role_string = "provider"
    when 'company customer'
      # grant user the 'company customer' role on the company
      user.grant_role('company customer', company)
      role_string = "customer"
    else
      # Just in case we get a role we don't recognize
      redirect_path = root_path
      flash[:error] = "Invalid role"
      return
    end

    if invitation
      # set the user as the invitation recipient
      invitation.recipient = user
      invitation.save
    end
    
    # mark user as activated
    user.activate!
    
    # set flash based on who created the user
    # set redirect path based on creator and role
    case creator
    when 'user'
      redirect_path  = "/#{role_string.pluralize}"
      flash[:notice]  = "#{role_string.titleize} #{user.name} was successfully created."
      
      begin
        # send account created notification
        MailWorker.async_send_account_created(:company_id => current_company.id, :creator_id => current_user.id, 
                                              :user_id => user.id, :password => user.password, :login_url => login_url)
      rescue Exception => e
        logger.debug("xxx error sending account created notification")
      end
    when 'anonymous'
      # cache the return to value (if it exists) before we reset the ression
      return_to       = session[:return_to]
      redirect_path  = return_to || "/"
      # kill the existing session
      logout_killing_session!
      # login as the new user
      self.current_user = user
      # set the flash after resetting the session
      flash[:notice]  = "Your account was successfully created. You are now logged in as #{user.name}"
    end
    
    redirect_path
  end 
end