require 'test/test_helper'

class ReportsControllerTest < ActionController::TestCase

  should_route :get, '/reports/range/20090101..20090201', :controller => 'reports', :action => 'show', :start_date => '20090101', :end_date => '20090201'
  should_route :get, '/reports/range/20090101..20090201/providers/1',
                     :controller => 'reports', :action => 'show', :start_date => '20090101', :end_date => '20090201', :provider_ids => '1'
  should_route :get, '/reports/range/20090101..20090201/services/1',
                     :controller => 'reports', :action => 'show', :start_date => '20090101', :end_date => '20090201', :service_ids => '1'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    # create provider
    @johnny       = Factory(:user, :name => "Johnny")
    @company.user_providers.push(@johnny)
    # create work service
    @haircut      = Factory.build(:work_service, :duration => 30.minutes, :name => "Haircut", :price => 1.00)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    # stub current company
    @controller.stubs(:current_company).returns(@company)
  end
  
  context "route" do
    context "range" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009"}}
      end

      should_redirect_to("report range path") { "/reports/range/20090801..20090901" }
    end

    context "range with anyone provider" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009", :provider => "users/0"}}
      end

      should_redirect_to("report providers path") { "/reports/range/20090801..20090901" }
    end

    context "range with provider" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009", :provider => "users/#{@johnny.id}"}}
      end

      should_redirect_to("report providers path") { "/reports/range/20090801..20090901/providers/#{@johnny.id}" }
    end

    context "range with service" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009", :service => "services/#{@haircut.id}"}}
      end

      should_redirect_to("report services path") { "/reports/range/20090801..20090901/services/#{@haircut.id}" }
    end
  end

  context "show" do
    context "range" do
      setup do
        get :show, :start_date => "08/01/2009", :end_date => "09/01/2009"
      end

      should_not_assign_to(:provider_ids)
      should_not_assign_to(:service_ids)
      should_assign_to(:text) { "Report from Aug 01 2009 to Sep 01 2009 for all services and providers" }

      should_respond_with(:success)
      should_render_template("reports/show.html.haml")
    end

    context "range for provider" do
      setup do
        get :show, :start_date => "08/01/2009", :end_date => "09/01/2009", :provider_ids => @johnny.id
      end

      should_assign_to(:provider_ids) { ["#{@johnny.id}"] }
      should_assign_to(:providers) { [@johnny] } 
      should_assign_to(:text) { "Report from Aug 01 2009 to Sep 01 2009 for Johnny" }

      should_respond_with(:success)
      should_render_template("reports/show.html.haml")
    end

    context "range for service" do
  
    end
  end
end