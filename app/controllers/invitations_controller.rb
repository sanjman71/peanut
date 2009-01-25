class InvitationsController < ApplicationController
  before_filter :init_current_company

  # GET /invitation/new
  def new
    @invitation = Invitation.new
  end
  
  # POST /invitations
  def create
    @invitation         = Invitation.new(params[:invitation])
    @invitation.sender  = current_user
    
    if @invitation.save
      MailWorker.async_send_invitation(:id => @invitation.id, :url => invite_url(@invitation.token))
      flash[:notice] = "Your invitation has been sent"
      redirect_to(users_path)
    else
      render :action => 'new'
    end
  end

  # GET /invitations/raise
  def raise
    
  end
  
end