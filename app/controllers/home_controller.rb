class HomeController < ApplicationController
  before_filter :disable_global_flash
  layout 'home'
  
  def index
    if @current_company
      # show company home page
      redirect_to openings_path(:subdomain => current_subdomain)
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
    
    respond_to do |format|
      format.html {render :action => :unauthorized, :layout => layout}
      format.js {page.redirect_to :action => :unauthorized}
    end
  end
  
end
