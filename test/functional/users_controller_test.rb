require 'test/test_helper'
require 'test/factories'

class UsersControllerTest < ActionController::TestCase

  def setup
    stub_subdomain
  end
  
  context "new user" do
  
    context "with no invitation" do

      setup do
        get :new
      end
    
      should_respond_with :success
      should_not_change "User.count"

    end
    
    context "with an invitation" do

      @sender = Factory(:user)
      @recipient_email = Factory.next(:email)

      @invitation = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company)
      assert_valid @invitation

      setup do
        get :new, :invitation_token => @invitation.token
      end

      should_respond_with :success
      should_not_change "User.count"

    end
    
  end


end
