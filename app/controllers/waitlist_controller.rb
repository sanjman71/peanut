class WaitlistController < ApplicationController
  privilege_required 'read wait appointments', :only => [:index], :on => :current_company

  def index
    if params[:provider_id].to_s == "0"
      # /users/0/waitlist is canonicalized to /waitlist; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :provider_id => nil, :provider_type => nil)))
    end
    
    # initialize provider
    @provider  = find_provider_from_params || User.anyone

    # build providers collection, including 'anyone'
    @providers = [User.anyone] + current_company.providers.all
    
    # find state (default to 'upcoming')
    @state        = params[:state] ? params[:state].to_s : 'upcoming'
    
    if @provider.anyone?
      # find waitlist appointments for anyone by state
      @appointments = @current_company.appointments.wait.send(@state)
      @anyone       = true
    else
      # find waitlist appointments for a provider by state
      @appointments = @current_company.appointments.wait.provider(@provider).send(@state)
      @anyone       = false
    end
    
    # group appointments by provider, map an empty provider to the special 'anyone' user
    @appointments_by_provider = @appointments.group_by{ |appt| appt.provider }.map{ |provider, appts| [provider || User.anyone, appts] }
    
    logger.debug("*** #{@appointments.size} waitlist appointments")

    # set title based on provider
    @title = "Waitlist for #{@provider.name}"
    
    respond_to do |format|
      format.html
    end
  end
  
  protected
  
  # find scheduable from the params hash
  def find_provider_from_params
    current_company.providers.find_by_provider_id_and_provider_type(params[:provider_id], params[:provider_type].to_s.classify)
  end
  
end