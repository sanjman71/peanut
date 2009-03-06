# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  def new
    # We show a signup form also, which requires a @user object
    @user = User.new
    if @current_company.blank?
      # use home layout
      render(:action => 'new', :layout => 'home')
    else
      # use default layout
      render(:action => 'new')
    end
  end

  def create
    logout_keeping_session!
    # authenticate user within a company domain; admins login with a company id of 0
    company_id  = @current_company.blank? ? 0 : @current_company.id
    user        = User.authenticate(params[:email], params[:password], :company_id => company_id)
    
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      
      # cache the return to value (if it exists) before we reset the ression
      return_to         = session[:return_to]
      reset_session
      self.current_user = user
      new_cookie_flag   = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      redirect_back_or_default(return_to || '/')
      flash[:notice] = "Logged in successfully"
    else
      note_failed_signin
      @user        = User.new
      @email       = params[:email]
      @remember_me = params[:remember_me]
      
      if @current_company.blank?
        # use home layout
        render(:action => 'new', :layout => 'home')
      else
        # use default layout
        render :action => 'new'
      end
    end
  end  

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  protected

  # Track failed login attempts
  def note_failed_signin
    flash.now[:error] = "Couldn't log you in as '#{params[:email]}'"
    logger.warn "Failed login for '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
