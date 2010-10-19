require 'test_helper'

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

  fast_context "index" do
    fast_context "for a company" do
      setup do
        # stub current company
        @controller.stubs(:current_company).returns(@company)
        get :index
      end

      should redirect_to("company openings path") { "/openings" }
    end

    fast_context "without a company" do
      setup do
        @request.host = "www.walnutcalendar.com"
        get :index
      end

      should respond_with :success
      should render_template 'home/index.html.haml'
    end

    fast_context "from mobile device" do
      fast_context "for a company" do
        setup do
          # stub current company
          @controller.stubs(:current_company).returns(@company)
          get :index, :mobile => '1'
        end

        should respond_with :success
        should render_template 'home/index.mobile.haml'
      end
    end
  end
end 