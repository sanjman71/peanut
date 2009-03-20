require 'test/test_helper'
require 'test/factories'

class UserTest < ActiveSupport::TestCase

  should_belong_to    :mobile_carrier
  should_belong_to    :invitation
  should_have_many    :subscriptions
  should_have_many    :plans, :through => :subscriptions
  
  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    assert_valid @company
  end
  
  context "create user without an invitation" do
    setup do
      @user1 = User.create(:company => @company, :name => "User 1", :email => "user1@jarna.com", 
                           :password => "secret", :password_confirmation => "secret")
    end
    
    should_change "User.count", :by => 1
    
    context "create another user without an invitation" do
      setup do
        @user2 = User.create(:company => @company, :name => "User 2", :email => "user2@jarna.com", 
                             :password => "secret", :password_confirmation => "secret")
      end
      
      should_change "User.count", :by => 1
    end
  end
  
  context "create user with a valid invitation" do
    setup do
      @recipient_email  = Factory.next(:user_email)
      @invitation       = Invitation.create(:sender => @owner, :recipient_email => @recipient_email, :company => @company)
      assert_valid @invitation
      @user             = User.create(:company => @company, :name => "User 3", :email => "user3@jarna.com", 
                                      :password => "secret", :password_confirmation => "secret",
                                      :invitation_id => @invitation.id)
      @user.reload
    end
    
    should_change "User.count", :by => 1
    
    should "have an invitation" do
      assert_equal @invitation, @user.invitation
    end
  end
  
end
