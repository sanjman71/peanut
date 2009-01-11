class InvitationNotifier < ActionMailer::Base

  def invitation(invitation, signup_url)
    setup_email
    recipients(invitation.recipient_email)
    subject("Peanut Invitation")
    body(:invitation => invitation, :signup_url => signup_url)
  end

  protected
  
  def setup_email
    from("peanut@jarna.com")
  end
  
end