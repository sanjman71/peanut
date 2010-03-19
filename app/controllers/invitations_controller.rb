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
    # only send invitations for company staff
    @invitation       = Invitation.new
    @invitation_roles = invitation_roles

    respond_to do |format|
      format.html
    end
  end

  # POST /invitations
  def create
    @invitation         = Invitation.new(params[:invitation])
    @invitation.sender  = current_user
    @invitation.company = current_company
    @email_address      = EmailAddress.with_emailable_user.with_address(@invitation.recipient_email).first

    if @email_address
      # user already exists; ask caller if they want to assign the user as a provider
      @user = @email_address.emailable
      @status = 'taken'
    elsif @invitation.save
      # valid invitation
      send_invitation(@invitation)
      @status = 'ok'
      @redirect_path = invitations_path
    else
      @status = 'error'
      @error = @invitation.errors.full_messages
      flash[:error] = @error
      @redirect_path = new_invitation_path
    end

    respond_to do |format|
      format.js do
        case @status
        when 'ok', 'error'
          render(:update) { |page| page.redirect_to(@redirect_path) }
        when 'taken'
          render(:action => 'create_taken')
        end
      end
    end
  end

  # GET /invitations/1/resend
  def resend
    @invitation = Invitation.find(params[:id])
    send_invitation(@invitation)
    redirect_to(invitations_path) and return
  end

  protected

  # allowed invitation roles
  def invitation_roles
    ['company staff']
  end

  def send_invitation(invitation)
    begin
      MessageComposeInvitation.staff(invitation, invite_url(invitation.token))
      flash[:notice] = "An invitation to #{invitation.recipient_email} has been sent"
    rescue Exception => e
      logger.debug("[error] invitation error: #{e.message}")
      flash[:error]  = "There was a problem sending your invitation"
    end
  end
  
end