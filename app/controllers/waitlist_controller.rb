class WaitlistController < ApplicationController
  before_filter :init_current_company

  def index
    @appointments = @current_company.appointments.wait
    
    logger.debug("*** #{@appointments.size} waitlist appointments")
  end
  
end