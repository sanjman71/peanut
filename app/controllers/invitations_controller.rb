class InvitationsController < ApplicationController

  # GET /invitation/new
  def new
    @invitation = Invitation.new
  end
  
  # POST /invitations
  def create
    @invitation         = Invitation.new(params[:invitation])
    @invitation.sender  = current_user
    @invitation.company = current_company
    
    if @invitation.save
      begin
        MailWorker.async_send_invitation(:id => @invitation.id, :url => invite_url(@invitation.token))
        flash[:notice] = "Your invitation has been sent"
      rescue Exception => e
        logger.debug("*** invitation error: #{e.message}")
        flash[:error]  = "There was a problem sending your invitation"
      end
      
      redirect_to(providers_path) and return
    else
      render(:action => 'new') and return
    end
  end

  # GET /invitations/raise
  def raise
    
  end
  
end