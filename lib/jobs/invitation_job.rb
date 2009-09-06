class InvitationJob < BaseJob
  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/invitations.log")
    end
  end

  def perform
    logger.info "#{Time.now}: [ok] invitation job: #{params.inspect}"

    begin
      invitation = Invitation.find(params[:id])
      invite_url  = params[:invite_url]
    rescue
      logger.error "#{Time.now}: [error] invalid invitation #{params[:id]}"
      return
    end

    begin
      case params[:method]
      when 'send_invitation'
        send_invitation(invitation, invite_url)
      else
        logger.error "#{Time.now}: [error] ignoring method #{params[:method]}"
      end
    rescue Exception => e
      logger.info "#{Time.now}: [error] #{e.message}, #{e.backtrace}"
    end
  end

  def send_invitation(invitation, invite_url)
    protocol  = 'email'
    address   = invitation.recipient_email
    subject   = "[#{invitation.company.name}] invitation"
    body      = "#{invitation.sender.name} invited you sign up for an account.  Your special invitation url is #{invite_url}"
    
    send_message_using_message_pub(subject, body, protocol, address)
    invitation.update_attributes(:sent_at => Time.now)
  end
end