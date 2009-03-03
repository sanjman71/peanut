require 'test/test_helper'
require 'test/factories'

class UsersControllerTest < ActionController::TestCase

  def setup
    @controller   = CustomersController.new
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
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

      setup do
        @sender = Factory(:user)
        @recipient_email = Factory.next(:user_email)
        @invitation = Invitation.create(:sender => @sender, :recipient_email => @recipient_email, :company => @company)
        assert_valid @invitation
        get :new, :invitation_token => @invitation.token
      end

      should_respond_with :success
      should_change "User.count", :by => 1 # for the sender user object
      should_change "Invitation.count", :by => 1
    end
    
  end


end
