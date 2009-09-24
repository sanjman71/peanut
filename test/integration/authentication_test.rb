require 'test/test_helper'

class AuthenticationTest < ActionController::IntegrationTest

  test "logging in with valid username and password" do
    @user = Factory(:user, :name => "Sanjay", :password => "secret")
    assert @user.valid?
    @user.email_addresses.create(:address => 'sanjay@jarna.com')
    visit login_url
    fill_in "email", :with => "sanjay@jarna.com"
    fill_in "password", :with => "secret"  
    click_button "Log in"
    assert_contain "Logged in as sanjay@jarna.com"
  end
  
end
