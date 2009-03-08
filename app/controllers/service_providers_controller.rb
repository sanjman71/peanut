class ServiceProvidersController < ApplicationController
  
  # POST /service_providers/create
  def create
    @sp = ServiceProvider.create(params[:service_provider])
    
    if !@sp.valid?
      logger.debug("*** errors: #{@sp.errors.full_messages}")
    end
    
    render_component(:controller => 'services',  :action => 'providers', :id => @sp.service.id,
                     :layout => false, :params => {:authenticity_token => params[:authenticity_token] })
  end
  
  # DELETE /service_providers/1
  def destroy
    @sp = ServiceProvider.find(params[:id])
    @sp.destroy
    
    render_component(:controller => 'services',  :action => 'providers', :id => @sp.service.id,
                     :layout => false, :params => {:authenticity_token => params[:authenticity_token] })
  end

end