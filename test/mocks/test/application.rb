#require 'controllers/application'

class ApplicationController < ActionController::Base 

  private
  
  def init_current_company
    # use a default subdomain in the test environment
    @current_company = Company.find_by_subdomain("company1")
    unless @current_company
      flash[:notice] = "Invalid company"
      redirect_to root_path
    end
  end
  
end
