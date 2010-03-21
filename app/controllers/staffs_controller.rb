class StaffsController < ApplicationController
  privilege_required 'read users', :only => [:index], :on => :current_company

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

end