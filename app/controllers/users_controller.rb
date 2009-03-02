class UsersController < ApplicationController
  
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]
  
  def index
    @users = current_company.authorized_users
  end
  
  def new
    @invitation = Invitation.find_by_token(params[:invitation_token])
    
    # if the invitation doesn't exist, give an error
    if @invitation.blank?
      @error = true
      return
    end

    # if the invitation has already been used, give an error
    if !@invitation.recipient.blank?
      @error = true
      return
    end

    # If the user already exists, we don't try to recreate them. Instead we add them to the company and redirect to the login page 
    if @user = User.find_by_email(@invitation.recipient_email)
      # add the invitation to the user's list of invitations
      @user.received_invitations << @invitation
      # add the user to the company
      @user.grant_role('company employee', @invitation.company)
      redirect_back_or_default('/login')
      flash[:notice] = "You have been added to #{@invitation.company.name}. Login to continue."
    end

    # We're creating a new user. Initialize the email from the invitation. The user gets to change this, however
    @user       = User.new()
    @user.email = @invitation.recipient_email
  end
 
  def create
    logout_keeping_session!
    @invitation = Invitation.find_by_token(params[:invitation_token])
    if @invitation.blank?
      @error = true
      return
    end
    
    @user = User.new(params[:user])
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      # Grant the user basic access to the company
      @user.grant_role('company employee', @invitation.company)
      # activate user, redirect to login page
      @user.activate!
      redirect_back_or_default('/login')
      flash[:notice] = "Your account was successfully created. Login to continue."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end

  # /users/1/edit
  def edit
    @user = User.find(params[:id])
  end
  
  def suspend
    @user.suspend! 
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end
  
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.

protected
  def find_user
    @user = User.find(params[:id])
  end
end
