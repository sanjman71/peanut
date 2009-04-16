require 'test/test_helper'
require 'test/factories'

class AuthenticationTest < ActionController::IntegrationTest

  test "logging in with valid username and password" do
    @user = Factory(:user, :email => "sanjay@jarna.com", :name => "Sanjay", :password => "secret")
    assert @user.valid?
    visit login_url
    fill_in "email", :with => "sanjay@jarna.com"
    fill_in "password", :with => "secret"  
    click_button "Log in"
    assert_contain "Logged in as #{@user.email}"
  end
  
end
