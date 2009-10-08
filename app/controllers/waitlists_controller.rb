class WaitlistsController < ApplicationController
  privilege_required 'read wait appointments', :only => [:index], :on => :current_company

  # GET /waitlists
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

  # GET /waitlist/users/1/services/3
  def new
    @title = "Waitlist Add"

    # initialize provider, service
    @provider = find_provider_from_params || User.anyone
    @service  = current_company.services.find(params[:service_id])
    @customer = current_user

    case
    when @customer.blank?
      @customer_signup = :rpx
      # set return_to url in case user uses rpx to login and needs to be redirected back
      session[:return_to] = request.url
    else
      @customer_signup = nil
    end
    
    # build waitlist object, and one child time range object
    @waitlist = Waitlist.new(:provider => @provider, :service => @service, :customer => @customer)
    @waitlist.waitlist_time_ranges.build

    respond_to do |format|
      format.html
    end
  end

  # POST /waitlist
  def create
    @wait_attrs = params[:waitlist].delete(:waitlist_time_ranges_attributes)
    @waitlist   = current_company.waitlists.create(params[:waitlist])

    if @waitlist.valid? and !@wait_attrs.blank?
      # updated nested attributes
      @waitlist.update_attributes(:waitlist_time_ranges_attributes => @wait_attrs)
    end

    if @waitlist.valid?
      flash[:notice]  = "You have been added to the waitlist"
      @redirect_path  = openings_path
    else
      flash[:error] = "There was an error adding you to the waitlist"
      logger.debug("[error] #{@waitlist.errors.full_messages}")
      @redirect_path = request.referer
    end

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js   { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end

  protected
  
  # find scheduable from the params hash
  def find_provider_from_params
    case params[:provider_type]
    when 'users', 'User'
      current_company.user_providers.find(params[:provider_id])
    else
      nil
    end
  end
  
end