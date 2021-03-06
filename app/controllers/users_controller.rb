class UsersController < ApplicationController
  before_filter :init_user, :only => [:edit, :update, :suspend, :unsuspend, :destroy, :purge, :add_rpx, :grant, :revoke]
  before_filter :init_role, :only => [:edit, :update, :destroy]
  before_filter :init_user_privileges, :only => [:edit, :update, :destroy]
  
  privilege_required      'create users', :only => [:new, :create], :on => :current_company
  privilege_required_any  'update users', :only => [:edit, :update, :destroy, :revoke], :on => [:user, :current_company]
  privilege_required      'update users', :only => [:add_rpx], :on => :user
  privilege_required      'update users', :only => [:grant], :on => :current_company
  privilege_required      'manage site', :only => [:index, :sudo]
  
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
      when 'company staff'
        # staff must be invited or user must have 'create users' privilege on the company
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

  @@per_page  = 25

  # GET /users
  def index
    @search = params[:q]

    if !@search.blank?
      case @search
      when '-companyroles'
        @users        = User.all(:include => :user_roles, :order => "users.name asc",
                                 :conditions => ["users.id not in (select distinct user_id from badges_user_roles where badges_user_roles.authorizable_type = 'Company')"])
        @search_text  = "Users with no company roles"
      else
        @users        = User.search_by_name_email_phone(@search).all(:include => :user_roles, :order => "users.name asc")
        @search_text  = "Users matching '#{@search}'"
      end
      @paginate     = false
    else
      @users        = User.all(:include => :user_roles, :order => "users.name asc").paginate(:page => params[:page], :per_page => @@per_page)
      @paginate     = true
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /staffs/new
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
        when 'company staff'
          # add the user as a company staff
          @invitation.company.grant_role(@invitation.role, @user) unless @invitation.company.blank?
        when 'company provider'
          # add the user as a company provider
          @invitation.company.user_providers.push(@user) unless @invitation.company.blank?
        when 'company customer'
          # add the user as a company customer
          @invitation.company.grant_role(@invitation.role, @user) unless @invitation.company.blank?
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

    # initialize return_to
    @return_to = params[:return_to] ? params[:return_to] : nil

    # initialize title
    @title = "#{@role.split[1].titleize} Signup"

    # check return_to param
    if !@return_to.blank?
      # store this location with return_to value
      store_location(@return_to)
      # use return_to as the back link
      @back_path = @return_to
    else
      # initialize back path to either the caller or the resource index page (e.g. /customers, /staffs), but only if there is a current user
      @back_path = current_user ? (request.referer || "/#{@role.pluralize}") : nil
    end

    respond_to do |format|
      format.html
    end
  end
 
  # POST /customers/create
  # POST /customers/create?return_to=
  # POST /staffs/create
  def create
    # @role (always) and @invitation (if it exists) are initialized in a before filter

    # xxx - temporarily disable this
    # logout_keeping_session!

    # initialize creator, default to anonymous
    @creator    = params[:creator] ? params[:creator] : 'anonymous'

    # initialize return_to
    @return_to  = params[:return_to] ? params[:return_to] : nil

    # check if user create is for a public or private company
    if !logged_in? and current_company and current_company.preferences[:public].to_i == 0
      # guest users may not create users for a private company
      flash[:error] = "You are not authorized to create a user account for this company"
      redirect_to root_path and return
    end

    # create user
    @user = User.create(params[:user])

    if @user.valid?
      # if there was an invitation, use the invitation company; otherwise use the current company
      @company = @invitation ? @invitation.company : current_company

      # store location if return_to was specified
      store_location(@return_to) unless @return_to.blank?

      # initialize the new user, and the redirect path
      @redirect_path = user_initialize(@company, @user, @role, @creator, @invitation)
    else
      @error         = true
      template       = 'users/new'
      @redirect_path = request.referer
      @title         = "#{@role.split[1].titleize} Signup"
      @back_path     = params[:return_to] ? params[:return_to] : nil
    end

    respond_to do |format|
      if @error
        format.html { render(:template => template) }
        format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
        format.json{ render(:json => Hash[:user => {:id => 0, :errors => @user.errors.full_messages}]) }
      else
        format.html { redirect_back_or_default(@redirect_path) }
        format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
        format.json do
          flash.discard
          render(:json => @user.to_json(:only => [:id, :name]))
        end
      end
    end
  end

  # GET /users/1/edit
  def edit
    # @role and @user are initialized here

    # always build an extra email and phone object for the form
    @user.email_addresses.build
    @user.phone_numbers.build

    # initialize user's primary email, phone
    @primary_email_address = @user.primary_email_address
    @primary_phone_number  = @user.primary_phone_number

    # build notes collection, most recent first
    @note     = Note.new
    @notes    = @user.notes.sort_recent

    # build the index path based on the user type
    @index_path = index_path(@user, @role)

    if @user.data_missing?
      if @user.phone_missing?
        flash.now[:notice] = "Please add a phone number to #{current_user == @user ? "your" : "this user's"} profile"
      elsif @user.email_missing?
        flash.now[:notice] = "Please add an email to #{current_user == @user ? "your" : "this user's"} profile"
      else
        flash.now[:error] = "User profile is missing required information"
      end
    end

    respond_to do |format|
      format.html
    end
  end
  
  # PUT /users/1
  def update
    # @role and @user are initialized here

    # build the index path based on the user type
    @index_path = index_path(@user, @role) || user_edit_path(@user)

    # always redirect back to user edit, unless there is a session back value
    @redirect_path = user_edit_path(@user)

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "User '#{@user.name}' was successfully updated"
        format.html { redirect_back_or_default(@redirect_path) }
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
    flash[:notice] = "Successfully logged in as #{@sudo_user.name}"
    redirect_to openings_path and return
  end

  # GET /users/1/add_rpx
  def add_rpx
    @rpx_emails = @user.email_addresses.select { |o| !o.identifier.blank? }

    respond_to do |format|
      format.html
    end
  end

  # PUT /users/1/grant/:role
  # valid roles: 'manager', 'provider'
  def grant
    @role = params[:role]

    case @role
    when 'staff'
      if !@user.has_role?('company staff', current_company)
        current_company.grant_role('company staff', @user)
        flash[:notice] = "User #{@user.name} has been added to the company staff"
      else
        flash[:notice] = "User #{@user.name} is already a company staff member"
      end
    when 'manager'
      if !@user.has_role?('company manager', current_company)
        current_company.grant_role('company manager', @user)
        flash[:notice] = "User #{@user.name} has been added as a company manager"
      else
        flash[:notice] = "User #{@user.name} is already a company manager"
      end
    when 'provider'
      if current_company.providers.include?(@user)
        flash[:notice] = "User #{@user.name} is already a company provider"
      elsif !current_company.may_add_provider?
        flash[:notice] = "Your company plan does not allow any more company providers.  Please upgrade your plan first."
      else
        current_company.user_providers.push(@user)
        flash[:notice] = "User #{@user.name} has been added as a company provider"
      end
    else
      flash[:notice] = "Invalid role"
    end

    @redirect_path = request.referer || user_edit_path(@user)
 
    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end

  # PUT /users/1/revoke/:role
  # valid roles: 'manager', 'provider'
  def revoke
    @role = params[:role]

    case @role
    when 'manager'
      if @user.has_role?('company manager', current_company)
        if @user == current_user
          flash[:notice] = "You can not remove yourself as a company manager"
        else
          current_company.revoke_role('company manager', @user)
          flash[:notice] = "User #{@user.name} has been removed as a company manager"
        end
      end
    when 'provider'
      # check if user is the provider, with the current company, for any free appointments
      if false #Appointment.free.provider(@user).company(current_company).size > 0
        # user can not be removed as a company provider until all appointments are removed
        flash[:notice] = "User #{@user.name} can not be removed as a company provider because they are a provider to at least 1 appointment."
        flash[:notice] += "<br/>Please remove these appointments and try again."
      else
        # remove user as a company provider
        if current_company.providers.include?(@user)
          current_company.user_providers.delete(@user)
          flash[:notice] = "User #{@user.name} has been removed as a company provider"
        else
          flash[:notice] = "User #{@user.name} is not a company provider"
        end
      end
    else
      flash[:notice] = "Invalid role"
    end

    @redirect_path = request.referer || user_edit_path(@user)

    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
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

  # DELETE /users/1
  def destroy
    # check user roles
    @company_roles = @user.roles.collect(&:name).uniq.select { |s| s.match(/^company/) }.sort

    # track exceptions
    @messages = []

    # check each role
    @company_roles.each do |role|
      case role
      when 'company customer'
        if @user.appointments_count > 0
          @messages.push("Can not delete a customer with appointments.")
        end
      when 'company manager'
        @messages.push("Can not delete company managers.")
      when 'company provider'
        @messages.push("Can not delete company providers.")
      end
    end

    if @messages.empty?
      @user.destroy
      flash[:notice] = "Deleted customer #{@user.name}"
    else
      flash[:notice] = @messages.join("<br/>")
    end

    @redirect_path = request.referer || users_path

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
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
      when @user.has_role?('company staff', current_company) || @user.has_role?('admin')
        @role = 'company staff'
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

  def index_path(user, role)
    # build the index path based on the user type
    case role
    when "company customer"
      case
      when (current_user == user)
        # no back when user editing themself
        nil
      when (request.referer != request.url)
        # back to referer
        request.referer
      else
        # default path
        customers_path
      end
    when "company staff"
      case
      when (current_user == user)
        # no back when user editing themself
        nil
      else
        # default path
        staffs_path
      end
    else
      root_path
    end
  end
  
end
