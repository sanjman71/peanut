class PeopleController < ApplicationController
  before_filter :init_current_company
  layout 'blueprint'
  
  # GET /people
  # GET /people.xml
  def index
    @search = params[:search]
    
    if !@search.blank?
      @people       = @current_company.people.search_name(@search).all(:order => "name ASC")
      @search_text  = "People matching '#{@search}'"
    else
      @people       = @current_company.people.all(:order => "name ASC")
      @search_text  = "All People"
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
    @person = @current_company.people.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @resource }
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    @person = Person.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/1/edit
  def edit
    @person = @current_company.people.find(params[:id])
  end

  # POST /resources
  # POST /resources.xml
  def create
    @person = Person.new(params[:people])

    respond_to do |format|
      if @person.save
        flash[:notice] = 'Person was successfully created.'
        format.html { redirect_to(@person) }
        format.xml  { render :xml => @person, :status => :created, :location => @resource }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /resources/1
  # PUT /resources/1.xml
  def update
    @person = @current_company.people.find(params[:id])

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
    @person = @current_company.people.find(params[:id])
    @person.destroy

    respond_to do |format|
      format.html { redirect_to(people_url) }
      format.xml  { head :ok }
    end
  end
end
