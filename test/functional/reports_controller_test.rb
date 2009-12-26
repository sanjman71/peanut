require 'test/test_helper'

class ReportsControllerTest < ActionController::TestCase

  # should_route :get, '/reports/range/20090101..20090201', :controller => 'reports', :action => 'show', :start_date => '20090101', :end_date => '20090201'
  should_route :get, '/reports/range/20090101..20090201/confirmed',
                     :controller => 'reports', :action => 'show', :start_date => '20090101', :end_date => '20090201', :state => 'confirmed'
  should_route :get, '/reports/range/20090101..20090201/all',
                     :controller => 'reports', :action => 'show', :start_date => '20090101', :end_date => '20090201', :state => 'all'
  should_route :get, '/reports/range/20090101..20090201/all/providers/1',
                     :controller => 'reports', :action => 'show', :start_date => '20090101', :end_date => '20090201', :state => 'all', :provider_ids => '1'
  should_route :get, '/reports/range/20090101..20090201/all/services/1',
                     :controller => 'reports', :action => 'show', :start_date => '20090101', :end_date => '20090201', :state => 'all', :service_ids => '1'

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
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009", :state => 'all'}}
      end

      should_redirect_to("report range path") { "/reports/range/20090801..20090901/all" }
    end

    context "range with anyone provider" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009", :state => 'confirmed', :provider => "users/0"}}
      end

      should_redirect_to("report providers path") { "/reports/range/20090801..20090901/confirmed" }
    end

    context "range with provider" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009", :state => 'all', :provider => "users/#{@johnny.id}"}}
      end

      should_redirect_to("report providers path") { "/reports/range/20090801..20090901/all/providers/#{@johnny.id}" }
    end

    context "range with service" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009", :state => 'all', :service => "services/#{@haircut.id}"}}
      end

      should_redirect_to("report services path") { "/reports/range/20090801..20090901/all/services/#{@haircut.id}" }
    end
  end

  context "show" do
    context "range" do
      setup do
        get :show, :start_date => "08/01/2009", :end_date => "09/01/2009", :state => 'all'
      end

      should_assign_to(:state) { 'all' }
      should_not_assign_to(:provider_ids)
      should_not_assign_to(:service_ids)
      should_assign_to(:text) { "All Appointments, All Services and Providers" }

      should_respond_with(:success)
      should_render_template("reports/show.html.haml")
    end

    context "range for provider" do
      setup do
        get :show, :start_date => "08/01/2009", :end_date => "09/01/2009", :state => 'all', :provider_ids => @johnny.id
      end

      should_assign_to(:state) { 'all' }
      should_assign_to(:provider_ids) { ["#{@johnny.id}"] }
      should_assign_to(:providers) { [@johnny] } 
      should_assign_to(:text) { "All Appointments, Provider Johnny" }

      should_respond_with(:success)
      should_render_template("reports/show.html.haml")
    end

    context "range for service" do
  
    end
  end
end