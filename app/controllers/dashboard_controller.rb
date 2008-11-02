class DashboardController < ApplicationController
  
  # GET /dashboard
  # GET /dashboard.xml
  def index
    @current_company = Company.find_by_subdomain(current_subdomain)
    
    if @current_company
      # show the dashboard for the current company
      layout = 'default'
    else
      # show the dashboard for the admin console
      layout = 'admin'
    end
    
    respond_to do |format|
      format.html { render :action => 'index', :layout => layout }
      format.xml  { head :ok }
    end
  end
  
end