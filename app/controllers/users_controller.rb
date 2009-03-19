class UsersController < ApplicationController
  before_filter :disable_global_flash, :only => [:index]
  
  privilege_required 'read users', :only => [:index], :on => :current_company
  privilege_required 'update users', :only => [:toggle_manager], :on => :current_company
  
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:edit, :suspend, :unsuspend, :destroy, :purge, :toggle_manager]
  
  def index
    # find all company users
    @users            = current_company.authorized_users.order_by_name.uniq
    
    # check if current user is a company manager
    @company_manager  = current_user.has_role?('company manager', current_company) || current_user.has_role?('admin')

    respond_to do |format|
      format.html
      format.json { render(:json => @users.to_json(:only => ['id', 'name', 'email'])) }
    end
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
    
    if params[:invitation_token]
      @invitation = Invitation.find_by_token(params[:invitation_token])
      if @invitation.blank?
        flash[:error] = "Your invitation code is invalid."
        @error = true
        return
      else
        # update the user params hash with the invitation id
        params[:user].update(:invitation_id => @invitation.id)
      end
    end
    
    @user = User.new(params[:user])
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      if !@invitation.blank?
        # Grant the user basic access to the company as a 'company employee'
        @user.grant_role('company employee', @invitation.company)
        # Add the user as a company schedulable
        @invitation.company.schedulables.push(@user)
        # Mark the user as the invitation recipient
        @invitation.recipient = @user
        @invitation.save
      end
      # activate user, redirect to login page
      @user.activate!
      flash[:notice] = "Your account was successfully created. Login to continue."
      redirect_to('/login')
    else
      flash.now[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :template => 'sessions/new'
    end
  end

  # /users/1/edit
  def edit
    
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
  
  # POST /users/:id/toggle_manager
  def toggle_manager
    if @user.has_role?('company manager', current_company)
      # revoke manager, grant employee
      @user.revoke_role('company manager', current_company)
      @user.grant_role('company employee', current_company)
    else
      # upgrade from employee to manager
      @user.revoke_role('company employee', current_company)
      @user.grant_role('company manager', current_company)
    end

    render_component(:controller => 'users',  :action => 'index', :layout => false, 
                     :params => {:authenticity_token => params[:authenticity_token] })
  end
  
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.

protected
  def find_user
    @user = User.find(params[:id])
  end
end
