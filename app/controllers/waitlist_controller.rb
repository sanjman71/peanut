class WaitlistController < ApplicationController
  privilege_required 'read waitlist', :only => [:index], :on => :current_company

  def index
    @appointments = @current_company.appointments.wait
    
    logger.debug("*** #{@appointments.size} waitlist appointments")
  end
  
end