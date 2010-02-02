class WaitlistsController < ApplicationController
  privilege_required 'manage site', :only => [:index], :on => :current_company

  # GET /waitlists
  def index
    if params[:provider_id].to_s == "0"
      # /users/0/waitlist is canonicalized to /waitlist; preserve subdomain on redirect
      return redirect_to(url_for(params.update(:subdomain => current_subdomain, :provider_id => nil, :provider_type => nil)))
    end
    
    # initialize provider
    @provider  = find_provider_from_params || User.anyone

    # build providers collection, including 'anyone'
    @providers = [User.anyone] + current_company.providers
    
    # find state (default to 'upcoming')
    # @state        = params[:state] ? params[:state].to_s : 'upcoming'
    
    if @provider.anyone?
      # find waitlist appointments for anyone by state
      @waitlists  = @current_company.waitlists
      @anyone     = true
    else
      # find waitlist appointments for a provider by state
      @waitlists  = @current_company.waitlists.provider(@provider)
      @anyone     = false
    end
    
    # group appointments by provider, map an empty provider to the special 'anyone' user
    @waitlists_by_provider = @waitlists.group_by{ |appt| appt.provider }.map{ |provider, appts| [provider || User.anyone, appts] }
    
    logger.debug("*** #{@waitlists.size} waitlist appointments")

    # set title based on provider
    @title = "Waitlist for #{@provider.name}"

    respond_to do |format|
      format.html
    end
  end

  # GET /waitlist/users/1/services/3
  # GET /waitlist/users/0/services/3  # 0 refers to the special 'anyone' user
  # def new
  #   @title = "Waitlist Add"
  # 
  #   # initialize provider, service
  #   @provider = find_provider_from_params || User.anyone
  #   @service  = current_company.services.find(params[:service_id])
  #   @customer = current_user || nil
  # 
  #   case
  #   when @customer.blank?
  #     @customer_signup = :rpx
  #     # set return_to url in case user uses rpx to login and needs to be redirected back
  #     session[:return_to] = request.url
  #   else
  #     @customer_signup = nil
  #   end
  # 
  #   # build waitlist object, and one child time range object
  #   @waitlist = Waitlist.new(:provider => @provider, :service => @service, :customer => @customer)
  #   @waitlist.waitlist_time_ranges.build
  # 
  #   respond_to do |format|
  #     format.html
  #   end
  # end

  # POST /waitlist
  def create
    # create waitlist with 0 or more time range attributes
    @waitlist = current_company.waitlists.create(params[:waitlist])

    if @waitlist.valid?
      flash[:notice]  = "You have been added to the waitlist"
      @redirect_path  = openings_path
    else
      flash[:error] = "There was an error adding you to the waitlist"
      logger.debug("[error] #{@waitlist.errors.full_messages}")
      @redirect_path = request.referer || openings_path
    end

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js   { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end

  protected

  # find provider from the params hash
  def find_provider_from_params
    case params[:provider_type]
    when 'users', 'User'
      if params[:provider_id].to_i == User.anyone.id
        User.anyone
      else
        current_company.user_providers.find(params[:provider_id])
      end
    else
      nil
    end
  end
  
end