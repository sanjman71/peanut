require 'test/test_helper'

class PhoneNumbersControllerTest < ActionController::TestCase

  should_route :get, '/users/1/phone/3/promote', :controller => 'phone_numbers', :action => 'promote', :user_id => '1', :id => '3' 
  should_route :delete, '/users/1/phone/3', :controller => 'phone_numbers', :action => 'destroy', :user_id => '1', :id => '3' 
  
  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    @user   = Factory(:user, :name => "User")
    @phone1 = @user.phone_numbers.create(:address => '2223876818', :name => 'Mobile', :priority => 1)
    @phone2 = @user.phone_numbers.create(:address => '5553876818', :name => 'Mobile', :priority => 5)
    @phone3 = @user.phone_numbers.create(:address => '3333876818', :name => 'Mobile', :priority => 3)
  end
  
  context "promote" do
    context "as guest" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        get :promote, :user_id => @user, :id => @phone3
      end

      should_redirect_to("unauthorized path") { "/unauthorized" }
    end
    
    setup do
      @controller.stubs(:current_user).returns(@user)
      get :promote, :user_id => @user, :id => @phone3
    end

    should "make phone3 primary phone number" do
      assert_equal @phone3, @user.reload.primary_phone_number
    end

    should "change phone3 priority to 1" do
      assert_equal 1, @phone3.reload.priority
    end

    should "change phone1 priority to 2" do
      assert_equal 2, @phone1.reload.priority
    end

    should "change phone2 priority to 2" do
      assert_equal 2, @phone2.reload.priority
    end

    should_redirect_to("user edit path") { "/users/#{@user.id}/edit" }
    should_set_the_flash_to /Changed primary phone number to 3333876818/i
  end
  
  context "destroy" do
    context "as guest" do
      setup do
        @controller.stubs(:current_user).returns(nil)
        delete :destroy, :user_id => @user, :id => @phone3
      end

      should_redirect_to("unauthorized path") { "/unauthorized" }
    end

    setup do
      @controller.stubs(:current_user).returns(@user)
      delete :destroy, :user_id => @user, :id => @phone3
    end

    should_change("phone number count", :by => -1) { PhoneNumber.count }

    should "change user.phone_numbers_count" do
      assert_equal 2, @user.reload.phone_numbers_count
    end

    should_redirect_to("user edit path") { "/users/#{@user.id}/edit" }
    should_set_the_flash_to /Removed phone number 3333876818/i
  end
end