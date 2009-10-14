require 'test/test_helper'

class MessagesControllerTest < ActionController::TestCase

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @user   = Factory(:user)
    @email  = @user.email_addresses.create(:address => "sanjay@walnutindustries.com")
  end
  
  context "create" do
    context "with messagable" do
      setup do
        post :create,
             {:message => {:body => "body", :subject => "hi", :sender_id => @user.id,
                           :message_recipients_attributes => {"0" => {:messagable_type => @email.class.to_s, :messagable_id => @email.id, :protocol => 'email'}}}}
      end

      should_change("message count", :by => 1) { Message.count }
      should_change("message recipient count", :by => 1) { MessageRecipient.count }
    
      should "change message recipient state to 'create'" do
        @message = Message.find(assigns(:message).id)
        @message_recipient = @message.message_recipients.first
        assert_equal 'created', @message_recipient.state
      end

      should_change("delayed job count", :by => 1) { Delayed::Job.count }
    end

    context "with message address" do
      setup do
        post :create,
             {:message => {:body => "body", :subject => "hi", :sender_id => @user.id, :address => 'sanjay@walnutindustries.com',
                           :message_recipients_attributes => {"0" => Hash[]}}}
      end

      should_change("message count", :by => 1) { Message.count }
      should_change("message recipient count", :by => 1) { MessageRecipient.count }
    end
  end
end