class ServiceProvidersController < ApplicationController
  
  # POST /service_providers/create
  def create
    @sp       = ServiceProvider.create(params[:service_provider])
    @service  = @sp.service
    
    if !@sp.valid?
      logger.debug("*** errors: #{@sp.errors.full_messages}")
    end
    
    render_service_providers(@service) and return
  end
  
  # DELETE /service_providers/1
  def destroy
    @sp       = ServiceProvider.find(params[:id])
    @service  = @sp.service
    @sp.destroy

    render_service_providers(@service) and return
  end

  protected
  
  def render_service_providers(service)
    # find servic providers, and all non providers
    @service            = @service
    @service_providers  = @service.service_providers
    @non_providers      = current_company.providers.all - @service.providers
    
    # render partial
    respond_to do |format|
      format.js { render(:action => 'providers') }
    end
  end
  
end