class HomeController < ApplicationController

  layout 'home'
  
  def index
    if current_company
      # show company home page
      redirect_to openings_path(:subdomain => current_subdomain) and return
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
  
  def faq
  end
  
  def demos
  end
  
end
