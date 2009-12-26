class ReportsController < ApplicationController
  before_filter :current_user

  privilege_required  'manage site', :only =>[:index], :on => :current_user

  # GET /reports/index
  def index
    @providers      = current_company.providers
    @sel_provider   = @providers.first
 
    @services       = current_company.services.work
    @sel_service    = @services.first

    @filters  = [['No Filter', 'any'], ['Provider', 'provider'], ['Service', 'service']] 
    @title    = "Build Your Report"

    respond_to do |format|
      format.html
    end
  end

  # POST /reports/route
  def route
    # parse start_date, end_date
    start_date  = sprintf("%s", params[:report][:start_date].split('/').reverse.swap!(1,2).join)
    end_date    = sprintf("%s", params[:report][:end_date].split('/').reverse.swap!(1,2).join)
    @state      = params[:report][:state].to_s

    # parse providers, services
    provider    = params[:report][:provider]
    providers   = params[:report][:providers]
    provider_id = provider.split("/")[1] if provider

    service     = params[:report][:service]
    services    = params[:report][:services]
    service_id  = service.split("/")[1] if service

    case
    when ((!provider_id.blank?) and (provider_id.to_i != 0)) # 0 means anyone
      # range with 1 provider
      redirect_to = report_providers_path(:start_date => start_date, :end_date => end_date, :state => @state, :provider_ids => provider_id)
    when ((!service_id.blank?) and (service_id.to_i != 0)) # 0 means any
      # range with 1 service
      redirect_to = report_services_path(:start_date => start_date, :end_date => end_date, :state => @state, :service_ids => service_id)
    else
      # range with no providers
      redirect_to = report_range_path(:start_date => start_date, :end_date => end_date, :state => @state)
    end

    respond_to do |format|
      format.html { redirect_to(redirect_to) }
      format.js   { render(:update) { |page| page.redirect_to(redirect_to) } }
    end
  end

  # GET /reports/range/20090101..20090201/all|confirmed
  # GET /reports/range/20090101..20090201/providers/1
  # GET /reports/range/20090101..20090201/services/1
  def show
    @start_date = Time.zone.parse(params[:start_date])
    @end_date   = Time.zone.parse(params[:end_date])
    @state      = params[:state].to_s

    if !params[:provider_ids].blank?
      @provider_ids = params[:provider_ids].split(',')
      @providers    = current_company.user_providers.find(@provider_ids)
    end

    if !params[:service_ids].blank?
      @service_ids = params[:service_ids].split(',')
      @services    = current_company.services.find(@service_ids)
    end

    @conditions = ["start_at >= ? AND start_at <= ?", @start_date, @end_date]
    @order      = 'appointments.start_at asc'
    @paginate   = Hash[:page => params[:page], :per_page => 20]

    case @state
    when 'all'
      @appointments = current_company.appointments.work.all(:conditions => @conditions, :order => @order).paginate(@paginate)
    else
      @appointments = current_company.appointments.work.send(@state).all(:conditions => @conditions, :order => @order).paginate(@paginate)
    end

    # tuple = ["Report from #{@start_date.to_s(:appt_short_month_day_year)} to #{@end_date.to_s(:appt_short_month_day_year)}"]
    tuple = ["#{@state.titleize} Appointments"]

    case
    when (@providers.blank? and @services.blank?)
      tuple.push("All Services and Providers")
    when !@providers.blank?
      if @providers.size == 1
        tuple.push("Provider #{@providers.collect(&:name).join(", ")}")
      else
        tuple.push("Providers #{@providers.collect(&:name).join(", ")}")
      end
    when !@services.blank?
      if @services.size == 1
        tuple.push("Service #{@services.collect(&:name).join(", ")}")
      else
        tuple.push("Services #{@services.collect(&:name).join(", ")}")
      end
    end

    @title  = "Custom Report"
    @text   = tuple.join(", ")

    respond_to do |format|
      format.html
    end
  end
end