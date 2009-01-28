class HomeController < ApplicationController
  before_filter :init_current_company
  layout 'signup'
  
  def index
    if @current_company
      # show company home page
      render(:template => 'companies/show', :layout => 'company') and return
    else
      # show www/root home page
      render(:action => :index, :layout => 'signup') and return
    end
  end
  
  # Handle all unauthorized access redirects
  def unauthorized
    if @current_company
      layout = 'company'
    else
      layout = 'signup'
    end
    
    render :action => :unauthorized, :layout => layout
  end
  
end
