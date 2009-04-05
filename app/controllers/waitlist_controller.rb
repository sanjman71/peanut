class WaitlistController < ApplicationController
  privilege_required 'read wait appointments', :only => [:index], :on => :current_company

  def index
    if params[:schedulable_id].to_s == "0"
      # /users/0/waitlist is canonicalized to /waitlist; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :schedulable_id => nil, :schedulable_type => nil)))
    end
    
    # initialize schedulable
    @schedulable  = find_schedulable_from_params || User.anyone

    # build schedulables collection, including 'anyone'
    @schedulables = [User.anyone] + current_company.schedulables.all
    
    # find state (default to 'upcoming')
    @state        = params[:state] ? params[:state].to_s : 'upcoming'
    
    if @schedulable.anyone?
      # find waitlist appointments for anyone by state
      @appointments = @current_company.appointments.wait.send(@state)
      @anyone       = true
    else
      # find waitlist appointments for a schedulable by state
      @appointments = @current_company.appointments.wait.schedulable(@schedulable).send(@state)
      @anyone       = false
    end
    
    # group appointments by schedulable, map an empty schedulable to the special 'anyone' user
    @appointments_by_schedulable = @appointments.group_by{ |appt| appt.schedulable }.map{ |schedulable, appts| [schedulable || User.anyone, appts] }
    
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