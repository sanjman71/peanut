class CompaniesController < ApplicationController
  before_filter :disable_global_flash, :only => [:edit]
  layout "company"

  privilege_required 'read companies', :only => [:index]
  privilege_required 'update companies', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete companies', :only => [:destroy], :on => :current_company

  # GET /companies
  # GET /companies.xml
  def index
    @companies = Company.all
    
    # find all companies w/ billing errors
    @billing_errors = Company.billing_errors
    
    respond_to do |format|
      # use home layout when listing all companies
      format.html { render :action => :index, :layout => 'home' }
    end
  end
  
  # GET /companies/1/edit
  def edit
    if (params[:id].blank? && current_company)
      @company = current_company
    else
      @company = Company.find(params[:id])
    end
    
    respond_to do |format|
      format.html
    end
  end

  # GET /companies/1/setup
  def setup
    # show setup page based on user type
    if !logged_in?
      # show customer setup for an anonymous user
      setup_type = 'customer'
    else
      setup_type = provider? ? 'provider' : 'customer'
    end
    
    respond_to do |format|
      format.html { render(:action => "setup_#{setup_type}") }
    end
  end
  
  # PUT /companies/1
  # PUT /companies/1.xml
  def update
    @company = Company.find(params[:id])
    if params[:company][:description]
      params[:company][:description] = Sanitize.clean(params[:company][:description], Sanitize::Config::RELAXED)
    end

    respond_to do |format|
      if @company.update_attributes(params[:company])
        flash[:notice] = 'Company was successfully updated.'
        # redirect to edit company page, since company show doesn't really show anything
        format.html { redirect_to(edit_company_root_path(:subdomain => @subdomain)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.xml
  def destroy
    @company.destroy

    respond_to do |format|
      format.html { redirect_to(companies_url) }
    end
  end
  
end
