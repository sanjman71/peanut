class ResourcesController < ApplicationController
  privilege_required 'create resources', :only => [:new, :create], :on => :current_company
  privilege_required 'read resources', :only => [:index, :show], :on => :current_company
  privilege_required 'update resources', :only => [:edit, :update], :on => :current_company
  privilege_required 'delete resources', :only => [:destroy], :on => :current_company
  
  # GET /resources
  def index
    @search = params[:search]
    
    if !@search.blank?
      @company_resources  = current_company.companies_resources.select { |cr| cr.resource.name.match(/#{@search}/i) }
      @search_text        = "Resources matching '#{@search}'"
    else
      @company_resources  = current_company.companies_resources
      @search_text        = @company_resources.blank? ? "No Resources" : "All Resources"
    end
  end

  # GET /resources/add
  def add
    # find users that are not resources
    @non_resources = current_company.authorized_users - current_company.users
    
    logger.debug("*** non resources: #{@non_resources}")
  end
  
end