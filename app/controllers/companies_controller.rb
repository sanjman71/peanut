class CompaniesController < ApplicationController
  after_filter :store_location, :only => [:index, :show, :edit]
  layout "company"

  privilege_required 'read companies', :only => [:index]
  privilege_required 'update companies', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete companies', :only => [:destroy], :on => :current_company

  # GET /companies
  # GET /companies.xml
  def index
    @companies = Company.find(:all)
    
    respond_to do |format|
      # use home layout when listing all companies
      format.html { render :action => :index, :layout => 'home' }
      format.xml  { render :xml => @companies }
    end
  end

  # GET /companies/1/edit
  def edit
    if (params[:id].blank? && current_company)
      @company = current_company
    else
      @company = Company.find(params[:id])
    end
  end
  
  # PUT /companies/1
  # PUT /companies/1.xml
  def update
    @company = Company.find(params[:id])

    respond_to do |format|
      if @company.update_attributes(params[:company])
        flash[:notice] = 'Company was successfully updated.'
        # redirect to edit company page, since company show doesn't really show anything
        format.html { redirect_to(edit_company_root_path(:subdomain => @subdomain)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.xml
  def destroy
    @company.destroy

    respond_to do |format|
      format.html { redirect_to(companies_url) }
      format.xml  { head :ok }
    end
  end
  
end
