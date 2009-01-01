class WaitlistController < ApplicationController
  before_filter :init_current_company
  layout 'blueprint'

  def index
    @appointments = @current_company.appointments.wait
    
    logger.debug("*** #{@appointments.size} waitlist appointments")
  end
  
end