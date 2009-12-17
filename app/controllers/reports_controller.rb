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
      redirect_to = report_providers_path(:start_date => start_date, :end_date => end_date, :provider_ids => provider_id)
    when ((!service_id.blank?) and (service_id.to_i != 0)) # 0 means any
      # range with 1 service
      redirect_to = report_services_path(:start_date => start_date, :end_date => end_date, :service_ids => service_id)
    else
      # range with no providers
      redirect_to = report_range_path(:start_date => start_date, :end_date => end_date)
    end

    respond_to do |format|
      format.html { redirect_to(redirect_to) }
      format.js   { render(:update) { |page| page.redirect_to(redirect_to) } }
    end
  end

  # GET /reports/range/20090101..20090201
  # GET /reports/range/20090101..20090201/providers/1
  # GET /reports/range/20090101..20090201/services/1
  def show
    @start_date = Time.zone.parse(params[:start_date])
    @end_date   = Time.zone.parse(params[:end_date])

    if !params[:provider_ids].blank?
      @provider_ids = params[:provider_ids].split(',')
      @providers    = current_company.user_providers.find(@provider_ids)
    end

    if !params[:service_ids].blank?
      @service_ids = params[:service_ids].split(',')
      @services    = current_company.services.find(@service_ids)
    end

    @appointments = current_company.appointments.work.not_canceled.all(:conditions => ["start_at >= ? AND start_at <= ?", @start_date, @end_date]).paginate(:page => params[:page], :per_page => 20)

    tuple = ["Report from #{@start_date.to_s(:appt_short_month_day_year)} to #{@end_date.to_s(:appt_short_month_day_year)}"]

    case
    when (@providers.blank? and @services.blank?)
      tuple.push("for all services and providers")
    when !@providers.blank?
      tuple.push("for #{@providers.collect(&:name).join(", ")}")
    when !@services.blank?
      tuple.push("for #{@services.collect(&:name).join(", ")}")
    end

    @title  = "Custom Report"
    @text   = tuple.join(" ")

    respond_to do |format|
      format.html
    end
  end
end