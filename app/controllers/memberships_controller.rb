class MembershipsController < ApplicationController
  before_filter :init_current_company
  layout 'default'
  
  # POST /create
  def create
    @membership = Membership.create(params[:membership])
    
    if !@membership.valid?
      logger.debug("*** errors: #{@membership.errors.full_messages}")
    end
    
    render_component :controller => 'services',  :action => 'memberships', :id => @membership.service.id,
                     :layout => false, :params => {:authenticity_token => params[:authenticity_token] }
  end
  
  # DELETE /services/1
  def destroy
    @membership = Membership.find(params[:id])
    @membership.destroy
    
    render_component :controller => 'services',  :action => 'memberships', :id => @membership.service,
                     :layout => false, :params => {:authenticity_token => params[:authenticity_token] }
  end

end