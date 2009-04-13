class PeopleController < ApplicationController
  privilege_required 'create people', :only => [:new, :create], :on => :current_company
  privilege_required 'read people', :only => [:index, :show], :on => :current_company
  privilege_required 'update people', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete people', :only => [:destroy], :on => :current_company
  
  # GET /people
  # GET /people.xml
  def index
    @search = params[:search]
    
    if !@search.blank?
      @people       = current_company.people.search_name(@search).all(:order => "name ASC")
      @search_text  = "People matching '#{@search}'"
    else
      @people       = current_company.people.all(:order => "name ASC")
      @search_text  = @people.blank? ? "No People" : "All People"
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @people }
      format.js
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show
    @person       = current_company.people.find(params[:id])
    
    # find associated services
    @services     = @person.services
    
    # find work appointments
    @appointments = current_company.appointments.resource(@person).work

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    if !current_company.may_add_resource?
      flash[:error] = "Your plan does not allow you to add another person."
      redirect_to(edit_company_root_path(:subdomain => current_subdomain)) and return
    end
    
    @person = Person.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/1/edit
  def edit
    @person = current_company.people.find(params[:id])
  end

  # POST /people
  # POST /people.xml
  def create
    if !current_company.may_add_resource?
      flash[:error] = "Your plan does not allow you to add another person."
      redirect_to(edit_company_root_path(:subdomain => current_subdomain)) and return
    end

    @person = Person.new(params[:person])

    if !@person.valid?
      @error      = true
      flash[:error] = "Could not create person"
      return
    end
    
    # save person
    @person.save
    
    # add person to company
    current_company.people.push(@person)
    
    # set redirect path
    @redirect_path = people_path
    
    flash[:notice] = "Created #{@person.name}"

    respond_to do |format|
      format.js # redirect to people index page
    end
  end

  # PUT /resources/1
  # PUT /resources/1.xml
  def update
    @person = current_company.people.find(params[:id])

    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /resources/1
  # DELETE /resources/1.xml
  def destroy
    @person = current_company.people.find(params[:id])
    @person.destroy

    respond_to do |format|
      format.html { redirect_to(people_url) }
      format.xml  { head :ok }
    end
  end
end
