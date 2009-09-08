require 'test/test_helper'
require 'test/factories'

class InvitationTest < ActiveSupport::TestCase

  context "create" do
    context "with invalid recipient email" do
      setup do
        @invitation = Invitation.create(:recipient_email => 's')
      end

      should_not_change("invitation count") { Invitation.count}
    end
    
    context "with valid recipient email" do
      setup do
        @invitation = Invitation.create(:recipient_email => 'sanjay@jarna.com')
      end
    
      should_change("invitation count", :by => 1) { Invitation.count}

      should "be a valid invitation" do
        assert_valid @invitation
      end
    
      should "have a valid token" do
        assert_not_nil @invitation.token
      end
    end
  end
  
  context "claimed" do
    context "without a recipient" do
      setup do
        @invitation = Invitation.create(:recipient_email => 'sanjay@jarna.com')
      end

      should "not be claimed" do
        assert !@invitation.claimed?
      end
    end

    context "with a recipient" do
      setup do
        @user       = Factory(:user, :name => "Sanjay")
        @invitation = Invitation.create(:recipient_email => 'sanjay@jarna.com')
        @invitation.recipient = @user
        @invitation.save
      end

      should "be claimed" do
        assert @invitation.claimed?
      end
    end

    context "with user having email" do
      setup do
        @user       = Factory(:user, :name => "Sanjay")
        @user.email_addresses.create(:address => "sanjay@jarna.com")
        @invitation = Invitation.create(:recipient_email => 'sanjay@jarna.com')
      end

      should "be claimed" do
        assert @invitation.claimed?
      end
    end
  end
end
