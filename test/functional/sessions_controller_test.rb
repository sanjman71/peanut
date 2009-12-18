require 'test/test_helper'

class SessionsControllerTest < ActionController::TestCase

  should_route :get, '/login', :controller => 'sessions', :action => 'new'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # @controller = SessionController.new
    # create company
    # @owner          = Factory(:user, :name => "Owner")
    @user       = Factory(:user, :name => "User", :password => 'user', :password_confirmation => 'user')
    @user_email = @user.email_addresses.create(:address => "user@walnut.com")
    assert @user_email.valid?
    @user_phone = @user.phone_numbers.create(:name => 'Mobile', :address => '6509999999')
    assert @user_phone.valid?
  end

  context "create session (login)" do
    context "with email address" do
      setup do
        post :create, {:email => 'user@walnut.com', :password => 'user'}
      end
      
      should_not_assign_to(:user)
  
      should_redirect_to("root path") { "/" }
    end

    context "with phone number" do
      setup do
        post :create, {:email => '650-999.9999', :password => 'user'}
      end
      
      should_not_assign_to(:user)
  
      should_redirect_to("root path") { "/" }
    end
    
  end

end