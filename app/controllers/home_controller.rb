class HomeController < ApplicationController
  before_filter :redirect_subdomain_home_route
  layout 'signup'
  
  def index
  end
end
