require 'test/test_helper'
require 'test/factories'

class ReportsControllerTest < ActionController::TestCase

  # should_route :get,  '/providers/new', :controller => 'users', :action => 'new', :role => 'company provider'
  # should_route :post, '/providers/create', :controller => 'users', :action => 'create', :role => 'company provider'
  # should_route :get,  '/providers/1/edit', :controller => 'users', :action => 'edit', :id => '1', :role => 'company provider'
  # should_route :put,  '/providers/1', :controller => 'users', :action => 'update', :id => '1', :role => 'company provider'

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
  end
  
  context "route" do
    context "range" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009"}}
      end
      
      should_redirect_to("report range path") { "/reports/range/20090801..20090901" }
    end
    
    context "range with provider" do
      setup do
        post :route, {:report => {:start_date => "08/01/2009", :end_date => "09/01/2009", :provider => "users/#{@johnny.id}"}}
      end
      
      should_redirect_to("report providers path") { "/reports/range/20090801..20090901/providers/#{@johnny.id}" }
    end
  end
  
end