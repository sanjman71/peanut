class EmployeesController < ApplicationController
  before_filter :disable_global_flash, :only => [:index]
  
  privilege_required 'read users', :only => [:index], :on => :current_company
  privilege_required 'update users', :only => [:toggle_manager], :on => :current_company
  
  # GET /employees
  def index
    # find all company employees
    @role   = Company.employee_role
    @users  = current_company.authorized_users.with_role(@role).order_by_name.uniq
    
    # check if current user is a company manager
    @company_manager = current_user.has_role?('company manager', current_company) || current_user.has_role?('admin')

    respond_to do |format|
      format.html
      format.js
      format.json { render(:json => @users.to_json(:only => ['id', 'name', 'email'])) }
    end
  end
  
  # POST /employees/:id/toggle_manager
  def toggle_manager
    @user = User.find(params[:id])
    
    if @user.has_role?('company manager', current_company)
      # revoke manager role
      @user.revoke_role('company manager', current_company)
    else
      # grant manager role
      @user.grant_role('company manager', current_company)
    end

    render_component(:controller => 'employees',  :action => 'index', :layout => false, 
                     :params => {:authenticity_token => params[:authenticity_token] })
  end
  
end