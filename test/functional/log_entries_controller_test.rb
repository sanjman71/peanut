require 'test/test_helper'
require 'test/factories'

class LogEntriesControllerTest < ActionController::TestCase

  # show log_entries index, optionally scoped by state
  should_route :get, '/log_entries', :controller => 'log_entries', :action => 'index'
  should_route :get, '/log_entries/seen', :controller => 'log_entries', :action => 'index', :state => 'seen'
  should_route :get, '/log_entries/unseen', :controller => 'log_entries', :action => 'index', :state => 'unseen'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @owner        = Factory(:user, :name => "Owner")
    @customer     = Factory(:user, :name => "Customer")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @provider     = Factory(:user, :name => "Provider")
    @company.providers.push(@provider)
    @service      = Factory(:work_service, :name => "Haircut", :price => 1.00)
    @company.services.push(@service)
    @appointment  = Factory(:appointment_today, :company => @company, :customer => @customer, :provider => @provider, :service => @service)
    @log_entry    = Factory(:log_entry, :company => @company, :user => @owner, :customer => @customer, :loggable => @appointment, :etype => LogEntry::INFORMATIONAL)
    # make owner the company manager
    @owner.grant_role('company manager', @company)
    # stub current company
    @controller.stubs(:current_company).returns(@company)
  end
  
  context "not logged in" do
    setup do
      @controller.stubs(:current_user).returns(nil)
      # ActionView::Base.any_instance.stubs(:current_user).returns(nil)
      get :index
    end

    should_respond_with :redirect
    should_redirect_to('unauthorized_path') { unauthorized_path }
    should_set_the_flash_to /You are not authorized/
  end
  
  # context "logged in as provider" do
  #   setup do
  #     @controller.stubs(:current_user).returns(@provider)
  #   end
  #   
  #   context "get log_entries index" do
  #     setup do
  #       get :index
  #     end
  #     
  #     should_respond_with :success
  #     should_render_template "log_entries/index.html.haml"
  #     should_assign_to :urgent
  #     should_assign_to :approval
  #     should_assign_to :informational
  #   end
  # 
  #   context "mark log_entry as seen" do
  #     setup do
  #       post :mark_as_seen, :id => @log_entry.id        
  #     end
  #     
  #     should_respond_with :redirect
  #     should_redirect_to 'unauthorized_path'
  #     should_set_the_flash_to /You are not authorized/
  #   end
  # end
  # 
  # context "logged in as manager" do
  #   setup do
  #     @controller.stubs(:current_user).returns(@owner)
  #   end
  # 
  #   context "get log_entries index" do
  #     setup do
  #       get :index
  #     end
  # 
  #     should_respond_with :success
  #     should_render_template "log_entries/index.html.haml"
  #     should_assign_to :urgent
  #     should_assign_to :approval
  #     should_assign_to :informational
  #   end
  # 
  #   context "mark log_entry as seen" do
  #     setup do
  #       post :mark_as_seen, :id => @log_entry.id        
  #     end
  # 
  #     should_respond_with :redirect
  #     # should_redirect_to 'dashboard_path'
  #   end
  # end
end
