class StaffsController < ApplicationController
  before_filter :init_staff, :only => [:index]

  privilege_required 'read users', :only => [:index], :on => :current_company
  privilege_required 'update users', :only => [:toggle_manager], :on => :current_company
  privilege_required 'create users', :only => [:assign, :assign_prompt], :on => :current_company

  @@per_page  = 10

  # GET /staffs
  def index
    # find all company staff and resources; even though resources are not currently shown
    @staff     = current_company.authorized_staff.paginate(:page => params[:page], :per_page => @@per_page)
    # @resources = current_company.resource_providers.paginate(:page => params[:page], :per_page => @@per_page)
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

  # GET /staffs/:id/assign_prompt
  def assign_prompt
    @user   = User.find(params[:id])
    @email  = @user.primary_email_address
    @title  = "Assign user as a company staff member"

    respond_to do |format|
      format.html
    end
  end

end