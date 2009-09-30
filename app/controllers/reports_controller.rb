class ReportsController < ApplicationController
  before_filter :current_user

  privilege_required  'read calendars', :only =>[:index], :on => :current_user

  # GET /reports/index
  def index
    @providers  = Array(current_user)
    @selected   = @providers.size > 1 ? User.anyone : @providers.first
 
    respond_to do |format|
      format.html
    end
  end

  # POST /reports/route
  def route
    # parse start_date, end_date
    start_date  = sprintf("%s", params[:report][:start_date].split('/').reverse.swap!(1,2).join)
    end_date    = sprintf("%s", params[:report][:end_date].split('/').reverse.swap!(1,2).join)

    # parse providers
    provider    = params[:report][:provider]
    providers   = params[:report][:providers]

    case
    when !provider.blank?
      provider_id = provider.split("/")[1]
      # range with 1 provider
      redirect_to = report_providers_path(:start_date => start_date, :end_date => end_date, :provider_ids => provider_id)
    else
      # range with no providers
      redirect_to = report_range_path(:start_date => start_date, :end_date => end_date)
    end

    respond_to do |format|
      format.html { redirect_to(redirect_to) }
      format.js   { render(:update) { |page| page.redirect_to(redirect_to) } }
    end
  end
  
  # GET /reports/show
  def show
    
    respond_to do |format|
      format.html
    end
  end
end