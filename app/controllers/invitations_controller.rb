class InvitationsController < ApplicationController

  privilege_required 'create users', :only => [:index, :new, :create, :resend], :on => :current_company
  
  # GET /invitations
  def index
    @invitations = current_company.invitations.with_sender(current_user).all(:order => 'sent_at asc')

    respond_to do |format|
      format.html
    end
  end

  # GET /invitation/new
  def new
    # only sent invitations for company providers
    @invitation       = Invitation.new
    @invitation_roles = ['company provider']

    respond_to do |format|
      format.html
    end
  end

  # POST /invitations
  def create
    @invitation         = Invitation.new(params[:invitation])
    @invitation.sender  = current_user
    @invitation.company = current_company
    @email_address      = EmailAddress.with_emailable_user.with_address(params[:invitation][:recipient_email]).first

    if @email_address
      # user already exists; ask caller if they want to assign the user as a provider
      @user = @email_address.emailable
      redirect_to(provider_assign_prompt_path(:id => @user.id)) and return
    elsif @invitation.save
      send_invitation(@invitation)
      redirect_to(invitations_path) and return
    else
      @invitation_roles = ['company provider']
      render(:action => 'new') and return
    end
  end

  # GET /invitations/1/resend
  def resend
    @invitation = Invitation.find(params[:id])
    send_invitation(@invitation)
    redirect_to(invitations_path) and return
  end
  
  protected
  
  def send_invitation(invitation)
    begin
      Delayed::Job.enqueue(InvitationJob.new(:id => invitation.id, :invite_url => invite_url(invitation.token), :method => 'send_invitation'))
      flash[:notice] = "An invitation to #{invitation.recipient_email} has been sent"
    rescue Exception => e
      logger.debug("*** invitation error: #{e.message}")
      flash[:error]  = "There was a problem sending your invitation"
    end
  end
   
end