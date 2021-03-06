require 'test_helper'

class InvitationsControllerTest < ActionController::TestCase

  should_route :get,  '/invitations/new', :controller => 'invitations', :action => 'new'
  should_route :get,  '/invitations/1/resend', :controller => 'invitations', :action => 'resend', :id => '1'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    @company = Factory(:company)
    @manager = Factory(:user, :name => "Owner")
    @company.grant_role('company manager', @manager)
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

    # context "with an invalid recipient email address" do
    #   setup do
    #     @controller.stubs(:current_user).returns(@manager)
    #     @controller.stubs(:current_company).returns(@company)
    #     post :create, :invitation => {:role => 'company provider', :recipient_email => 's'}
    #   end
    # 
    #   should_not_change("invitation count") { Invitation.count }
    #   should_render_template("invitations/new.html.haml")
    # end

    context "for a new company provider" do
      setup do
        @controller.stubs(:current_user).returns(@manager)
        @controller.stubs(:current_company).returns(@company)
        xhr :post, :create, :format => 'js', :invitation => {:role => 'company provider', :recipient_email => 'sanjay@jarna.com'}
      end

      should_assign_to(:invitation)
      should_assign_to(:status) { 'ok' }
      should_assign_to(:redirect_path) { '/invitations' }
      should_change("invitation count", :by => 1) { Invitation.count }
      should_change("delayed job count", :by => 1) { Delayed::Job.count}

      should "set invitation role to 'company provider'" do
        assert_equal 'company provider', assigns(:invitation).role
      end

      should "increment invitation.sent count" do
        assert_equal 1, assigns(:invitation).sent
      end

      # sent_at timestamp is updated when delayed job sends the message
      should "set invitation.last_sent_at timestamp to nil" do
        assert_equal nil, assigns(:invitation).last_sent_at
      end

      should_respond_with :success
      should_respond_with_content_type "text/javascript"
    end

    context "for a new company staff" do
      setup do
        @controller.stubs(:current_user).returns(@manager)
        @controller.stubs(:current_company).returns(@company)
        xhr :post, :create, :format => 'js', :invitation => {:role => 'company staff', :recipient_email => 'sanjay@jarna.com'}
      end

      should_assign_to(:invitation)
      should_assign_to(:status) { 'ok' }
      should_assign_to(:redirect_path) { '/invitations' }
      should_change("invitation count", :by => 1) { Invitation.count }
      should_change("delayed job count", :by => 1) { Delayed::Job.count}

      should "set invitation role to 'company staff'" do
        assert_equal 'company staff', assigns(:invitation).role
      end

      should "increment invitation.sent count" do
        assert_equal 1, assigns(:invitation).sent
      end

      # sent_at timestamp is updated when delayed job sends the message
      should "set invitation.last_sent_at timestamp to nil" do
        assert_equal nil, assigns(:invitation).last_sent_at
      end

      should_respond_with :success
      should_respond_with_content_type "text/javascript"
    end

    context "for an existing user" do
      setup do
        @user = Factory(:user)
        @user.email_addresses.create(:address => 'sanjay@walnut.com')
        @controller.stubs(:current_user).returns(@manager)
        @controller.stubs(:current_company).returns(@company)
        xhr :post, :create, :format => 'js', :invitation => {:role => 'company provider', :recipient_email => 'sanjay@walnut.com'}
      end

      should_assign_to(:invitation)
      should_assign_to(:status) { 'taken' }
      should_not_change("invitation count") { Invitation.count }
      should_not_change("delayed job count") { Delayed::Job.count}

      should_respond_with :success
      should_respond_with_content_type "text/javascript"
      should_render_template "invitations/create_taken.js.rjs"
    end
  end
end