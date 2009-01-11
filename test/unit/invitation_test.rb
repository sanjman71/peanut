require 'test/test_helper'
require 'test/factories'

class InvitationTest < ActiveSupport::TestCase

  context "create" do
    setup do
      @invitation = Invitation.create(:recipient_email => 'sanjay@jarna.com')
    end
    
    should "be a valid invitation" do
      assert_valid @invitation
    end
    
    should "have a valid token" do
      assert_not_nil @invitation.token
    end
  end
end
