require 'test/test_helper'

class EmailAddressesControllerTest < ActionController::TestCase

  should_route :get, '/users/1/email/3/promote', :controller => 'email_addresses', :action => 'promote', :user_id => '1', :id => '3' 
  should_route :delete, '/users/1/email/3', :controller => 'email_addresses', :action => 'destroy', :user_id => '1', :id => '3' 
  
  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    @user = Factory(:user, :name => "User")
    @email1 = @user.email_addresses.create(:address => 'email1@walnutindustries.com', :priority => 1)
    @email2 = @user.email_addresses.create(:address => 'email2@walnutindustries.com', :priority => 5)
    @email3 = @user.email_addresses.create(:address => 'email3@walnutindustries.com', :priority => 3)
  end
  
  context "promote" do
    context "as guest" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        get :promote, :user_id => @user, :id => @email3
      end

      should_redirect_to("unauthorized path") { "/unauthorized" }
    end
    
    setup do
      @controller.stubs(:current_user).returns(@user)
      get :promote, :user_id => @user, :id => @email3
    end

    should "make email3 primary email address" do
      assert_equal @email3, @user.reload.primary_email_address
    end

    should "change email3 priority to 1" do
      assert_equal 1, @email3.reload.priority
    end

    should "change email1 priority to 2" do
      assert_equal 2, @email1.reload.priority
    end

    should "change email2 priority to 2" do
      assert_equal 2, @email2.reload.priority
    end

    should_redirect_to("user edit path") { "/users/#{@user.id}/edit" }
    should_set_the_flash_to /Changed primary email address to email3@walnutindustries.com/i
  end
  
  context "destroy" do
    context "as guest" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        delete :destroy, :user_id => @user, :id => @email3
      end

      should_redirect_to("unauthorized path") { "/unauthorized" }
    end

    setup do
      @controller.stubs(:current_user).returns(@user)
      delete :destroy, :user_id => @user, :id => @email3
    end

    should_change("email address count", :by => -1) { EmailAddress.count }

    should "change user.email_addresses_count" do
      assert_equal 2, @user.reload.email_addresses_count
    end

    should_redirect_to("user edit path") { "/users/#{@user.id}/edit" }
    should_set_the_flash_to /Removed email address email3@walnutindustries.com/i
  end
end