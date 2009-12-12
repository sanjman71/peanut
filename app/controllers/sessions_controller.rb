# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  include UserSessionHelper

  def new
    # We show a signup form also, which requires a @user object
    @user = User.new
    if current_company.blank?
      # use home layout, don't allow signups from here
      @signup = false
      render(:action => 'new', :layout => 'home')
    else
      # use default layout, disable signups
      @signup = false
      render(:action => 'new')
    end
  end

  def create
    logout_keeping_session!

    # authenticate user
    user = User.authenticate(params[:email], params[:password])

    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.

      redirect_path = session_initialize(user)
      redirect_back_or_default(redirect_path) and return
    else
      note_failed_signin
      @user        = User.new
      @email       = params[:email]
      @remember_me = params[:remember_me]
      
      if current_company.blank?
        # use home layout, don't allow signups from here
        @signup = false
        render(:action => 'new', :layout => 'home')
      else
        # use default layout, disable signup
        @signup = false
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
