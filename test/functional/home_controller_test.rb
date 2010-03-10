require 'test/test_helper'

class HomeControllerTest < ActionController::TestCase

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company, with 2 managers
    @owner        = Factory(:user, :name => "Owner")
    @owner.email_addresses.create(:address => 'owner@walnutcalendar.com')
    @manager      = Factory(:user, :name => "Manager")
    @manager.email_addresses.create(:address => 'manager@walnutcalendar.com')
    @monthly_plan = Factory(:monthly_plan)
    # create subscription in active state
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @subscription.authorized!
    @subscription.active!
    @company      = Factory(:company, :subscription => @subscription, :subdomain => 'widgets')
    @owner.grant_role('company manager', @company)
    @manager.grant_role('company manager', @company)
  end

  context "index" do
    context "for a company" do
      setup do
        @request.host = "#{@company.subdomain}.walnutcalendar.com"
        # stub current company
        @controller.stubs(:current_company).returns(@company)
        get :index
      end

      should_redirect_to("company openings path") { "/openings" }
    end

    context "without a company" do
      setup do
        @request.host = "www.walnutcalendar.com"
        get :index
      end

      should_respond_with :success
      should_render_template 'home/index.html.haml'
    end

    context "from mobile device" do
      context "for a company" do
        setup do
          @request.host = "#{@company.subdomain}.walnutcalendar.com"
          # stub current company
          @controller.stubs(:current_company).returns(@company)
          get :index, :mobile => '1'
        end

        should_respond_with :success
        should_render_template 'home/index.mobile.haml'
      end
    end
  end
end 