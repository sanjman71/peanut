class CompaniesController < ApplicationController
  before_filter :init_current_company
  before_filter :get_context, :only => [:index, :show, :edit, :update, :destroy] # Not for new and create
  after_filter :store_location, :only => [:index, :show, :edit]

  # GET /companies
  # GET /companies.xml
  def index

    if @current_company
      # show company openings
      return redirect_to(openings_path)
    end
    
    # We're going to an admin page
    # need to check permission here
    @companies = Company.find(:all)
    
    respond_to do |format|
      format.html { render :layout => 'admin' } # index.html.erb
      format.xml  { render :xml => @companies }
    end
  end

  # GET /companies/1
  # GET /companies/1.xml
  def show
    respond_to do |format|
      format.html { redirect_to(appointments_path) }
      format.xml  { render :xml => @company }
    end
  end

  # GET /companies/new
  # GET /companies/new.xml
  def new
    @company = Company.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @company }
    end
  end

  # GET /companies/1/edit
  def edit
  end
  
  # POST /companies
  # POST /companies.xml
  def create
    @company = Company.new(params[:company])

    respond_to do |format|
      if @company.save
        flash[:notice] = 'Company was successfully created.'
        format.html { redirect_to(companies_path) }
        format.xml  { render :xml => @company, :status => :created, :location => @company }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /companies/1
  # PUT /companies/1.xml
  def update

    respond_to do |format|
      if @company.update_attributes(params[:company])
        flash[:notice] = 'Company was successfully updated.'
        format.html { redirect_to(companies_path) }
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
  
  def get_context
    if @current_company
      @company = @current_company
    elsif params && params[:id]
      @company = Company.find(params[:id])
    end
    # We do authorization on the parent as appropriate. 
    @may_edit_parent = has_privilege?("update company", @company)
	end
  
end
