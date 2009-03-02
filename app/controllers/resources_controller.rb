class ResourcesController < ApplicationController
  privilege_required 'create resources', :only => [:new, :create], :on => :current_company
  privilege_required 'read resources', :only => [:index, :show], :on => :current_company
  privilege_required 'update resources', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete resources', :only => [:destroy], :on => :current_company
  
  # GET /resources
  def index
    @search = params[:search]
    
    if !@search.blank?
      @resources    = current_company.resources.select { |r| r.name.match(/#{@search}/i) }
      @search_text  = "Resources matching '#{@search}'"
    else
      @resources    = current_company.resources.all
      @search_text  = @resources.blank? ? "No Resources" : "All Resources"
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  # GET /resources/add
  def add
    # find users that are not resources
    @non_resources = current_company.authorized_users - current_company.users
  end
  
end