require 'test/test_helper'
require 'test/factories'

class PasswordsControllerTest < ActionController::TestCase

  should_route :get,  '/password/forgot', :controller => 'passwords', :action => 'forgot'
  should_route :post, '/password/reset', :controller => 'passwords', :action => 'reset'

  def setup
    @user = Factory(:user, :email => "sanjay@jarna.com")
  end
  
  context "reset" do
    context "for an invalid user" do
      setup do
        post :reset, {:email => 'bogus@jarna.com'}
      end

      should_not_assign_to(:user)

      should "set flash error" do
        assert_match /Could not find the specified email address/, flash[:error]
      end

      should_redirect_to("password forgot path") { password_forgot_path }
    end

    context "for a valid user" do
      setup do
        post :reset, {:email => 'sanjay@jarna.com'}
      end

      should_assign_to(:user)

      should "change user password to a random password" do
        user = User.find_by_email("sanjay@jarna.com")
        assert User.authenticate('sanjay@jarna.com', assigns(:user).password)
      end

      should_redirect_to("login path") { login_path }
    end
  end
end