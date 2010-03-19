class CompaniesController < ApplicationController
  layout "company"

  privilege_required 'manage site', :only => [:index, :freeze, :unfreeze]
  privilege_required 'update companies', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete companies', :only => [:destroy], :on => :current_company

  # GET /companies
  def index
    # companies with subscriptions indicate they are peanut customers
    @companies      = Company.with_subscriptions.all(:include => :subscription)

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
      setup_type = (provider? || manager?) ? 'provider' : 'customer'
    end
    
    respond_to do |format|
      format.html { render(:action => "setup_#{setup_type}") }
    end
  end
  
  # PUT /companies/1
  def update
    @company = Company.find(params[:id])

    if params[:company][:description]
      params[:company][:description] = Sanitize.clean(params[:company][:description], Sanitize::Config::WALNUT)
    end

    respond_to do |format|
      if @company.update_attributes(params[:company])
        flash[:notice] = 'Company was successfully updated.'
        # redirect to edit company page, since company show doesn't really show anything
        format.html { redirect_to(edit_company_root_path(:subdomain => current_subdomain)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # PUT /companies/1/freeze
  def freeze
    @company = Company.find(params[:id])
    @company.subscription.frozen!

    flash[:notice] = "Changed company '#{@company.name}' account state to frozen"

    respond_to do |format|
      format.html { redirect_to(companies_path)}
    end
  end

  # PUT /companies/1/unfreeze
  def unfreeze
    @company = Company.find(params[:id])
    @company.subscription.active!

    flash[:notice] = "Changed company '#{@company.name}' account state to active"

    respond_to do |format|
      format.html { redirect_to(companies_path)}
    end
  end

  # DELETE /companies/1
  def destroy
    @company.destroy

    respond_to do |format|
      format.html { redirect_to(companies_url) }
    end
  end
  
end
