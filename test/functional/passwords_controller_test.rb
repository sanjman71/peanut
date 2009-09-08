require 'test/test_helper'
require 'test/factories'

class PasswordsControllerTest < ActionController::TestCase

  should_route :get,  '/password/forgot', :controller => 'passwords', :action => 'forgot'
  should_route :post, '/password/reset', :controller => 'passwords', :action => 'reset'

  def setup
    @user  = Factory(:user)
    @email = @user.email_addresses.create(:address => "sanjay@walnut.com")
  end
  
  context "reset" do
    context "for an invalid user" do
      setup do
        post :reset, {:email => 'bogus@walnut.com'}
      end

      should_not_assign_to(:user)

      should "set flash error" do
        assert_match /Could not find the specified email address/, flash[:error]
      end

      should_redirect_to("password forgot path") { password_forgot_path }
    end

    context "for a valid user" do
      setup do
        post :reset, {:email => 'sanjay@walnut.com'}
      end

      should_assign_to(:user)

      should "change user password to a random password" do
        user = User.with_email("sanjay@walnut.com").first
        assert User.authenticate('sanjay@walnut.com', assigns(:user).password)
      end

      should_redirect_to("login path") { login_path }
    end
  end
end