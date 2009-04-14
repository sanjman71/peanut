require 'test/test_helper'
require 'test/factories'

class UserTest < ActiveSupport::TestCase

  should_belong_to    :mobile_carrier
  should_have_many    :subscriptions
  should_have_many    :plans, :through => :subscriptions
  should_have_many    :appointments
  
  context "create user with extra phone characters" do
    setup do
      @user = User.create(:name => "User 1", :email => "user1@jarna.com", 
                          :password => "secret", :password_confirmation => "secret", :phone => "(650) 387-6818")
    end
    
    should_change "User.count", :by => 1

    should "have only digits in phone" do
      assert_equal "6503876818", @user.phone
    end
    
    should "have only digits in phone after an update" do
      @user.update_attributes(:phone => "650-387-6818")
      @user.reload
      assert_equal "6503876818", @user.phone
    end
  end
  
  context "create user" do
    setup do
      @user1 = User.create(:name => "User 1", :email => "user1@jarna.com", :password => "secret", :password_confirmation => "secret")
    end
    
    should_change "User.count", :by => 1
    
    context "create another user" do
      setup do
        @user2 = User.create(:name => "User 2", :email => "user2@jarna.com", :password => "secret", :password_confirmation => "secret")
      end
      
      should_change "User.count", :by => 1
    end
  end  
end
