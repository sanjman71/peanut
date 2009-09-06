require 'test/test_helper'
require 'test/factories'

class InvitationsControllerTest < ActionController::TestCase

  should_route :get,  '/invitations/new', :controller => 'invitations', :action => 'new'
  should_route :get,  '/invitations/1/resend', :controller => 'invitations', :action => 'resend', :id => '1'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @company = Factory(:company)
    @manager = Factory(:user, :name => "Owner")
    @manager.grant_role('company manager', @company)
  end
  
  context "create invitation" do
    context "without create users privilege" do
      setup do
        @user = Factory(:user)
        @controller.stubs(:current_user).returns(@user)
        post :create, :invitaton => {}
      end
      
      should_redirect_to("unauthorized") { unauthorized_path }
    end

    context "with an invalid recipient email address" do
      setup do
        @controller.stubs(:current_user).returns(@manager)
        @controller.stubs(:current_company).returns(@company)
        post :create, :invitation => {:role => 'company provider', :recipient_email => 's'}
      end

      should_not_change("invitation count") { Invitation.count }
      should_render_template("invitations/new.html.haml")
    end
    
    context "for a new provider" do
      setup do
        @controller.stubs(:current_user).returns(@manager)
        @controller.stubs(:current_company).returns(@company)
        post :create, :invitation => {:role => 'company provider', :recipient_email => 'sanjay@jarna.com'}
      end

      should_change("invitation count", :by => 1) { Invitation.count }
      should_redirect_to("invitations path") { invitations_path }
    end

    context "for an existing user" do
      setup do
        @user = Factory(:user, :email => "sanjay@jarna.com")
        @controller.stubs(:current_user).returns(@manager)
        @controller.stubs(:current_company).returns(@company)
        post :create, :invitation => {:role => 'company provider', :recipient_email => 'sanjay@jarna.com'}
      end

      should_not_change("invitation count") { Invitation.count }
      should_redirect_to("providers assign prompt") { provider_assign_prompt_path(@user.id) }
    end
  end
end