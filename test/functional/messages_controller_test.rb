require 'test/test_helper'

class MessagesControllerTest < ActionController::TestCase

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    @company = Factory(:company)
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
    @user   = Factory(:user)
    @email  = @user.email_addresses.create(:address => "sanjay@walnutindustries.com")
  end
  
  context "create" do
    # context "with messagable" do
    #   setup do
    #     @controller.stubs(:current_user).returns(@user)
    #     post :create,
    #          {:message => {:body => "body", :subject => "hi", :sender_id => @user.id,
    #                        :message_recipients_attributes => {"0" => {:messagable_type => @email.class.to_s, :messagable_id => @email.id, :protocol => 'email'}}}}
    #   end
    # 
    #   should_change("message count", :by => 1) { Message.count }
    #   should_change("message recipient count", :by => 1) { MessageRecipient.count }
    # 
    #   should "change message recipient state to 'created'" do
    #     @message = Message.find(assigns(:message).id)
    #     @message_recipient = @message.message_recipients.first
    #     assert_equal 'created', @message_recipient.state
    #   end
    # 
    #   should_change("delayed job count", :by => 1) { Delayed::Job.count }
    # end

    context "with message address" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        post :create,
             {:message => {:body => "body", :subject => "hi", :sender_id => @user.id, :address => 'sanjay@walnutindustries.com',
                           :message_recipients_attributes => {"0" => Hash[]}}}
      end

      should_assign_to(:sender_id) { @user.id}
      should_assign_to(:sender) { @user}
      should_assign_to(:subject) { "hi" }
      should_assign_to(:body) { "body" }
      should_assign_to(:recipients) { [@email] }
      should_assign_to(:topic) { @company }
      should_assign_to(:tag) { "message" }

      should_change("message count", :by => 1) { Message.count }
      should_change("message recipient count", :by => 1) { MessageRecipient.count }
      should_change("delayed job count", :by => 1) { Delayed::Job.count }
    end
  end
end