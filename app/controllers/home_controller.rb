class HomeController < ApplicationController
  layout 'home'
  
  def index
    if @current_company
      # show company home page
      redirect_to show_company_root_path(:subdomain => current_subdomain)
      # render(:template => 'companies/show', :layout => 'company') and return
    else
      # show www/root home page
      render(:action => :index, :layout => 'home') and return
    end
  end
  
  # Handle all unauthorized access redirects
  def unauthorized
    if @current_company
      layout = 'company'
    else
      layout = 'home'
    end
    
    render :action => :unauthorized, :layout => layout
  end
  
end
