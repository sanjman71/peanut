class ReportsController < ApplicationController
  before_filter :current_user

  privilege_required  'read calendars', :only =>[:index], :on => :current_user

  # GET /reports/index
  def index
    @providers  = Array(current_user)
    @selected   = @providers.size > 1 ? User.anyone : @providers.first
 
    respond_to do |format|
      format.html
    end
  end

  # POST /reports/format
  def format
    # format post parameters and redirect to properly formatted url
  end
  
  # GET /reports/show
  def show
    
  end
end