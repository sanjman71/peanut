require 'test/test_helper'
require 'test/factories'

class UserTest < ActiveSupport::TestCase

  context "create user" do
    setup do
      @user = User.create(:company_id => 0, :name => "", :email => "user1@jarna.com", :password => "secret", :password_confirmation => "secret")
    end
    
    should "be a valid user" do
      assert_valid @user
    end
  end
end
