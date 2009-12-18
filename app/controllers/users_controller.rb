class UsersController < ApplicationController
  before_filter :init_user, :only => [:edit, :update, :suspend, :unsuspend, :destroy, :purge]
  before_filter :init_role, :only => [:edit, :update]
  before_filter :init_user_privileges, :only => [:edit, :update]
  
  privilege_required      'create users', :only => [:new, :create], :on => :current_company
  privilege_required_any  'update users', :only => [:edit, :update], :on => [:user, :current_company]
  privilege_required      'manage site', :only => [:sudo], :on => :current_company
  
  def has_privilege?(p, authorizable=nil, user=nil)
    case p
    when 'create users'
      @role = init_role
      
      begin
        # if we have an invitation, use invitation role
        @invitation = params[:invitation_token] ? Invitation.find_by_token!(params[:invitation_token]) : nil
        @role       = @invitation.role if @invitation
      rescue ActiveRecord::RecordNotFound => e
        return false
      end
      
      case @role
      when 'company customer'
        # anyone can signup as a customer
        return true
      when 'company provider'
        # providers must be invited or user must have 'create users' privilege on the company
        return true if @invitation
        super
      else
        # any other role is not allowed
        return false
      end
      # delegate to base class
      super
    else
      # delegate to base class
      super
    end
  end
  
  # GET /providers/new
  # GET /customers/new
  # GET /customers/new?return_to=
  # GET /invite/dc8a032b9ae52f5c7710f53a945efbc11bb7ce51
  def new
    # @role (always) and @invitation (if it exists) have been initialized at this point

    if @invitation
      # if the invitation has already been used, give an error
      if !@invitation.recipient.blank?
        @error_message = "Your invitation is invalid" and return
      end
      
      # if the user already exists, don't try to recreate them
      # instead add them to the company and redirect to the login page 
      if @user = User.with_email(@invitation.recipient_email).first
        # add the invitation to the user's list of invitations
        @user.received_invitations << @invitation
        case @invitation.role
        when 'company provider'
          # add the user as a company provider
          @invitation.company.user_providers.push(@user) unless @invitation.company.blank?
        when 'company customer'
          # grant user customer role
          @user.grant_role('company customer', @invitation.company) unless @invitation.company.blank?
        end 
        # set the flash message
        flash[:notice] = "You have been added to #{@invitation.company.name}. Login to continue."
        redirect_back_or_default('/login') and return
      end
    end  

    # build a new user; initialize the email from the invitation, but allow the user to change it
    @user = User.new

    if @invitation
      @user.email_addresses_attributes = [{:address => @invitation.recipient_email}]
    else
      # build an email and phone nested object
      @user.email_addresses.build
      @user.phone_numbers.build
    end
    # @user.email = @invitation.recipient_email if @invitation

    # initialize title
    @title      = "#{@role.split[1].titleize} Signup"

    # check return_to param
    if params[:return_to]
      # store this location
      store_location(params[:return_to])
      # use return_to as the back link
      @back_path = params[:return_to]
    else
      # initialize back path to either the caller or the resource index page (e.g. /customers, /providers), but only if there is a current user
      @back_path  = current_user ? (request.referer || "/#{@role.pluralize}") : nil
    end

    respond_to do |format|
      format.html
    end
  end
 
  # POST /customers/create
  # POST /providers/create
  def create
    # @role (always) and @invitation (if it exists) are initialized in a before filter
    
    # xxx - temporarily disable this
    # logout_keeping_session!

    # initialize creator, default to anonymous
    @creator = params[:creator] ? params[:creator] : 'anonymous'
    
    if @creator == 'user' and (params[:user][:password].blank? and params[:user][:password_confirmation].blank?)
      # generate random password for the new user
      params[:user][:password] = :random
    end

    # create user
    @user = User.create_or_reset(params[:user])
    
    # @user.register! if @user && @user.valid?
    # success = @user && @user.valid?
    
    # if success && @user.errors.empty?
    if @user.valid?
      # if there was an invitation, use the invitation company; otherwise use the current company
      @company        = @invitation ? @invitation.company : current_company
      
      # initialize the new user
      @redirect_path  = user_initialize(@company, @user, @role, @creator, @invitation)
    else
      @error    = true
      template  ='users/new'
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
    # @role and @user are initialized here

    # build email and phone attributes for the form
    @user.email_addresses.build unless @user.email_addresses_count > 0
    @user.phone_numbers.build unless @user.phone_numbers_count > 0

    # build notes collection, most recent first
    @note     = Note.new
    @notes    = @user.notes.sort_recent
    
    # build the index path based on the user type
    @index_path = index_path(@role)
    
    respond_to do |format|
      format.html
    end
  end
  
  def update
    # @role and @user are initialized here

    # build the index path based on the user type
    @index_path = index_path(@role)
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "User '#{@user.name}' was successfully updated"
        format.html { redirect_to(@index_path) }
      else
        format.html { render(:action => 'edit') }
      end
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please login to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end

  # GET /users/1/sudo
  def sudo
    @sudo_user = User.find_by_id(params[:id])
    if @sudo_user.blank?
      flash[:error] = "Invalid user"
      redirect_to request.referer and return
    end

    # change current user
    self.current_user = @sudo_user
    flash[:notice] = "Now logged in as #{@sudo_user.name}"
    redirect_to request.referer and return
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
  
  # POST /users/exists
  def exists
    @email = params[:email]
    @user  = User.new(:email => @email)
    @user.valid?
    @error = @user.errors.on(:email)
    @hash  = @error.blank? ? Hash[:email => 'ok'] : Hash[:email => "email #{@error}"]

    respond_to do |format|
      format.js { render(:json => @hash.to_json) }
      format.json { render(:json => @hash.to_json) }
    end
  end
    
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.

  protected
  
  def init_user
    @user = User.find(params[:id])
  end
  
  def init_role
    @role = params[:role]
    
    if @role.blank?
      # figure out type based on user
      return @role if @user.blank?
      case
      when @user.has_role?('company provider', current_company) || @user.has_role?('admin')
        @role = 'company provider'
      else
        @role = 'company customer'
      end
    end
    
    @role
  end

  def init_user_privileges
    if current_user and @user
      @current_privileges[@user] = current_user.privileges(@user).collect(&:name)
    end
  end

  def index_path(role)
    # build the index path based on the user type
    case role
    when "company customer"
      openings_path
    when "company provider"
      "/providers"
    else
      root_path
    end
  end
  
end
