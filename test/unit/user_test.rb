require 'test/test_helper'
require 'test/factories'

class UserTest < ActiveSupport::TestCase

  context "create" do
    setup do
      @user = User.create(:company_id => 0, :email => "user1@jarna.com", :password => "secret", :password_confirmation => "secret",
                          :invitation_id => User.make_token)
    end
    
    should "be a valid user" do
      assert_valid @user
    end
  end
end
