class WaitlistController < ApplicationController
  before_filter :init_current_company

  privilege_required 'read appointments', :only => [:index], :on => :current_company

  def index
    @appointments = @current_company.appointments.wait
    
    logger.debug("*** #{@appointments.size} waitlist appointments")
  end
  
end