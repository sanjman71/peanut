class CompaniesResourcesController < ApplicationController
  
  # POST /company_resources/create
  def create
    @company_resource = CompaniesResource.create(params[:resource].update(:company_id => current_company.id))
    
    if !@company_resource.valid?
      logger.debug("*** errors: #{@company_resource.errors.full_messages}")
    end
    
    render_component(:controller => 'resources', :action => 'add', :layout => false, :method => :get)
  end
  
  # DELETE /services/1
  def destroy
    @company_resource = CompaniesResource.find(params[:id])
    @company_resource.destroy
    
    render_component(:controller => 'resources',  :action => 'index',
                     :layout => false, :params => {:authenticity_token => params[:authenticity_token] })
  end

end