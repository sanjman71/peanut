require 'test/test_helper'
require 'test/factories'

class UserTest < ActiveSupport::TestCase

  should_belong_to    :mobile_carrier
  should_belong_to    :invitation
  should_have_many    :subscriptions
  should_have_many    :plans, :through => :subscriptions
  
  context "create without an invitation" do
    setup do
      @user1 = User.create(:company_id => 0, :name => "User 1", :email => "user1@jarna.com", :password => "secret", :password_confirmation => "secret")
    end
    
    should "be a valid user" do
      assert_valid @user1
    end
    should_change "User.count", :by => 1
    
    context "create another user without an invitation" do
      setup do
        @user2 = User.create(:company_id => 0, :name => "User 2", :email => "user2@jarna.com", :password => "secret", :password_confirmation => "secret")
      end
      
      should "be a valid user" do
        assert_valid @user2
      end
      should_change "User.count", :by => 1
    end

    # context "create user with a valid invitation" do
    #   setup do
    #     @invitation1 = Invitation.create
    #     @user3       = User.create(:company_id => 0, :email => "user2@jarna.com", :password => "secret", :password_confirmation => "secret")
    #   end
    #   
    #   should "not be a valid user" do
    #     assert !@user3.valid?
    #     assert_match /blank/, @user3.errors[:invitation_id]
    #   end
    #   should_not_change "User.count"
    # end
  end
end
