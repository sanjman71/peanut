class HomeController < ApplicationController
  before_filter :redirect_subdomain_home_route, :only => [:index]
  layout 'signup'
  
  def index
  end
  
  # Handle all unauthorized access redirects
  def unauthorized
    init_current_company
    
    if @current_company
      layout = 'company'
    else
      layout = 'signup'
    end
    
    render :action => :unauthorized, :layout => layout
  end
  
end
