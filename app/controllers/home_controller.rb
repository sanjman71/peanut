class HomeController < ApplicationController
  before_filter :init_current_company
  layout 'home'
  
  def index
    if @current_company
      # show company home page
      render(:template => 'companies/show', :layout => 'company') and return
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
