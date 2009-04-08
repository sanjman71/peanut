class ProvidersController < ApplicationController
  before_filter :disable_global_flash, :only => [:index]
  
  privilege_required 'read users', :only => [:index], :on => :current_company
  privilege_required 'update users', :only => [:toggle_manager], :on => :current_company
  
  # GET /providers
  def index
    # find all company providers
    @users  = current_company.authorized_users.with_role(Company.provider_role).order_by_name.uniq
    
    respond_to do |format|
      format.html
      format.js
      format.json { render(:json => @users.to_json(:only => ['id', 'name', 'email'])) }
    end
  end
  
  # POST /providers/:id/toggle_manager
  def toggle_manager
    @user = User.find(params[:id])
    
    if @user.has_role?('manager', current_company)
      # revoke manager role, but a user may not revoke this role on himself
      @user.revoke_role('manager', current_company) unless (@user == current_user)
    else
      # grant manager role
      @user.grant_role('manager', current_company)
    end

    # redirect to providers index
    @redirect_path = providers_path

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js { render(:update) {|page| page.redirect_to(@redirect_path) } }
    end
  end
  
end