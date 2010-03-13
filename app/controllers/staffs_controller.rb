class ProvidersController < ApplicationController
  before_filter :init_staff, :only => [:index]

  privilege_required 'read users', :only => [:index], :on => :current_company
  privilege_required 'update users', :only => [:toggle_manager], :on => :current_company
  privilege_required 'create users', :only => [:assign, :assign_prompt], :on => :current_company

  @@per_page  = 10

  # GET /providers
  def index
    # find all company staff and resources; even though resources are not currently shown
    @staff     = current_company.authorized_staff.paginate(:page => params[:providers_page], :per_page => @@per_page)
    @resources = current_company.resource_providers.paginate(:page => params[:resources_page], :per_page => @@per_page)
    @paginate  = true

    respond_to do |format|
      format.html
      format.js
      format.json { render(:json => @staff.to_json(:only => ['id', 'name', 'email'])) }
    end
  end

  # temporary method to initalize company staff role for all company managers and providers
  def init_staff
    current_company.authorized_managers_and_providers.each do |user|
      next if user.has_role?('company staff', current_company)
      current_company.grant_role('company staff', user)
    end
  end

  # POST /providers/:id/toggle_manager
  def toggle_manager
    @user = User.find(params[:id])
    
    if @user.has_role?('company manager', current_company)
      # revoke manager role, but a user may not revoke this role on himself
      @user.revoke_role('company manager', current_company) unless (@user == current_user)
    else
      # grant manager role
      @user.grant_role('company manager', current_company)
    end

    # redirect to providers index
    @redirect_path = providers_path

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end
  
  # POST /providers/:id/toggle_provider
  def toggle_provider
    @user = User.find(params[:id])
    
    if current_company.user_providers.include?(@user)
      # remove user as provider
      current_company.user_providers.delete(@user)
    else
      # add user as provider
      current_company.user_providers.push(@user)
    end

    # redirect to providers index
    @redirect_path = providers_path

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end

  # GET /providers/:id/assign_prompt
  def assign_prompt
    @user   = User.find(params[:id])
    @email  = @user.primary_email_address
    @title  = "Assign user as a company provider"

    respond_to do |format|
      format.html
    end
  end
  
  # PUT /providers/:id/assign
  def assign
    @user = User.find(params[:id])
    
    unless current_company.user_providers.include?(@user)
      # current_company.user_providers.push(@user)
      flash[:notice] = "Added user #{@user.name} as a company provider"
    end
    
    redirect_to(providers_path) and return
  end
end