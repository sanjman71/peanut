class AppointmentWaitlistsController < ApplicationController
  privilege_required 'read wait appointments', :only => [:index], :on => :current_company

  # GET /waitlists/appointments/1
  def show
    @appointment  = Appointment.find(params[:appointment_id])
    @waitlists    = @appointment.waitlists.all(:include => :customer)
    
    logger.debug("*** waitlists: #{@waitlists.inspect}")

    respond_to do |format|
      format.js
    end
  end
  
end