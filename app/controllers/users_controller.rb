class UsersController < ApplicationController
  before_filter :disable_global_flash, :only => [:new, :create]
  
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:edit, :suspend, :unsuspend, :destroy, :purge, :toggle_manager]
  
  privilege_required 'create users', :only => [:new, :create], :on => :current_company
  
  def has_privilege?(p, *args)
    case p
    when 'create users'
      authorizable  = args[0]
      user          = args[1] || current_user
      @type         = params[:type]
      
      begin
        @invitation = params[:invitation_token] ? Invitation.find_by_token!(params[:invitation_token]) : nil
      rescue ActiveRecord::RecordNotFound => e
        return false
      end
      
      case @type
      when 'customer'
        # anyone can signup as a customer
        return true
      when 'employee'
        # employees must be invited or user must have 'create users' privilege
        return true if @invitation or current_privileges.include?(p)
        return false
      else
        # not allowed
        return false
      end
      # delegate to base class
      super
    else
      super
    end
  end
  
  # GET /employees/new
  # GET /employees/new?invitation_token=xyz
  # GET /customers/new
  def new
    # @type (always) and @invitation (if it exists) have been initialized at this point

    if @invitation
      # if the invitation has already been used, give an error
      if !@invitation.recipient.blank?
        @error_message = "Your invitation is invalid" and return
      end
      
      # if the user already exists, don't try to recreate them
      # instead add them to the company and redirect to the login page 
      if @user = User.find_by_email(@invitation.recipient_email)
        # add the invitation to the user's list of invitations
        @user.received_invitations << @invitation
        # add the user to the company
        @user.grant_role('company employee', @invitation.company)
        redirect_back_or_default('/login')
        flash[:notice] = "You have been added to #{@invitation.company.name}. Login to continue."
      end
    end  

    # We're creating a new user. Initialize the email from the invitation. The user gets to change this, however
    @user       = User.new
    @user.email = @invitation.recipient_email if @invitation
    
    # initialize back path to either the caller or the resource index page (e.g. /customers, /employees), but only if there is a current user
    @back_path  = current_user ? (request.referer || "/#{@type.pluralize}") : nil
  end
 
  def create
    # @type (always) and @invitation (if it exists) have been initialized at this point
    
    # xxx - temporarily disable this
    # logout_keeping_session!

    @user = User.new(params[:user])
    @user.invitation = @invitation if @invitation
    
    # initialize creator, default to anonymous
    @creator = params[:creator] ? params[:creator] : 'anonymous'
    
    if @creator == 'user' and (params[:user][:password].blank? or params[:user][:password_confirmation].blank?)
      # generate random password for the new user
      @user.password = @user.password_confirmation = random_password
    end
    
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    
    if success && @user.errors.empty?
      # if there was an invitation, then use the invitation company; otherwise use the current company
      @company = @invitation ? @invitation.company : current_company
      
      case @type
      when 'employee'
        # grant the user basic access to the company as a 'company employee'
        @user.grant_role('company employee', @company)
        # add the user as a company schedulable
        @company.schedulables.push(@user)
      when 'customer'
        # grant the user the 'customer' role
        @user.grant_role('customer', @company)
      end

      if @invitation
        # set the user as the invitation recipient
        @invitation.recipient = @user
        @invitation.save
      end
      
      # activate user, redirect to login page
      @user.activate!
      
      # set flash based on who created the user
      # set redirect path based on creator and type
      case @creator
      when 'user'
        @redirect_path  = "/#{@type.pluralize}"
        flash[:notice]  = "#{@type.titleize} #{@user.name} was successfully created."
      when 'anonymous'
        @redirect_path  = "/login" 
        flash[:notice]  = "Your account was successfully created. Login to continue."
      end
    else
      @error    = true
      template  ='users/new'
      flash.now[:error] = "We could not set up that account, sorry.  Please try again, or contact an admin (link is above)."
    end
    
    respond_to do |format|
      if @error
        format.html { render(:template => template) }
      else
        format.html { redirect_back_or_default(@redirect_path) }
      end
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
  
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.

  protected
  
  def find_user
    @user = User.find(params[:id])
  end
  
  def random_password
    'peanut'
    # User.make_token
  end
end
