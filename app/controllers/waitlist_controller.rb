class WaitlistController < ApplicationController
  privilege_required 'read wait appointments', :only => [:index], :on => :current_company

  def index
    if params[:schedulable_type].blank? or params[:schedulable_id].blank?
      # no schedulable was specified, redirect to the company's first schedulable
      schedulable = current_company.schedulables.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :schedulable_type => schedulable.tableize, :schedulable_id => schedulable.id)) and return
    end
    
    # initialize schedulable
    @schedulable  = find_schedulable_from_params
    @schedulables = current_company.schedulables.all
    
    # find state (default to 'upcoming')
    @state        = params[:state] ? params[:state].to_s : 'upcoming'
    
    # find a schedulable's waitlist appointments by state
    @appointments = @current_company.appointments.wait.schedulable(@schedulable).send(@state)
    
    logger.debug("*** #{@appointments.size} waitlist appointments")
    
    # set title based on schedulable
    @title = "Waitlist for #{@schedulable.name}"
    
    respond_to do |format|
      format.html
    end
  end
  
  protected
  
  # find scheduable from the params hash
  def find_schedulable_from_params
    current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:schedulable_id], params[:schedulable_type].to_s.classify)
  end
  
end