require 'test/test_helper'

class PasswordsControllerTest < ActionController::TestCase

  should_route :get,  '/password/forgot', :controller => 'passwords', :action => 'forgot'
  should_route :post, '/password/reset', :controller => 'passwords', :action => 'reset'
  should_route :put,  '/users/1/password/clear', :controller => 'passwords', :action => 'clear', :id => '1'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    @user  = Factory(:user, :password => 'secret', :password_confirmation => 'secret')
    @email = @user.email_addresses.create(:address => "sanjay@walnut.com")
  end
  
  context "reset" do
    context "for an invalid user" do
      setup do
        post :reset, {:email => 'bogus@walnut.com'}
      end

      should_not_assign_to(:user)

      should "set flash error" do
        assert_match /Invalid email address/, flash[:error]
      end

      should_redirect_to("password forgot path") { password_forgot_path }
    end

    context "for a valid user" do
      setup do
        post :reset, {:email => 'sanjay@walnut.com'}
      end

      should_assign_to(:user)
      should_assign_to(:password)

      should "change user password to a random password" do
        user = User.with_email("sanjay@walnut.com").first
        assert User.authenticate('sanjay@walnut.com', assigns(:password))
      end

      should_redirect_to("login path") { login_path }
    end
  end
  
  context "clear" do
    setup do
      @controller.stubs(:current_user).returns(@user)
      @request.env['HTTP_REFERER'] = "/users/#{@user.id}/edit"
      put :clear, :id => @user.id
    end

    should_assign_to(:user)
    
    should "remove user password" do
      assert_nil @user.reload.crypted_password
    end

    should_redirect_to("referer") { "/users/#{@user.id}/edit" }
  end

end