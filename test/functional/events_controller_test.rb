require 'test/test_helper'
require 'test/factories'

class EventsControllerTest < ActionController::TestCase

  # show events index, optionally scoped by state
  should_route :get, '/events', :controller => 'events', :action => 'index'
  should_route :get, '/events/seen', :controller => 'events', :action => 'index', :state => 'seen'
  should_route :get, '/events/unseen', :controller => 'events', :action => 'index', :state => 'unseen'

  def setup
    @owner        = Factory(:user, :name => "Owner")
    @customer     = Factory(:user, :name => "Customer")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @employee     = Factory(:user, :name => "Employee", :companies => [@company])
    @service      = Factory(:work_service, :name => "Haircut", :companies => [@company], :price => 1.00)
    @appointment  = Factory(:appointment_today, :company => @company, :customer => @customer, :schedulable => @employee, :service => @service)
    @event        = Factory(:event, :company => @company, :user => @owner, :customer => @customer, :eventable => @appointment, :etype => Event::INFORMATIONAL)
    # make owner the company manager
    @owner.grant_role('company manager', @company)
    @owner.grant_role('company employee', @company)
    @employee.grant_role('company employee', @company)
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
    
  end
  
  context "Not logged in" do
    setup do
      @controller.stubs(:current_privileges).returns([])
      ActionView::Base.any_instance.stubs(:current_privileges).returns([])
      @controller.stubs(:current_user).returns(nil)
      ActionView::Base.any_instance.stubs(:current_user).returns(nil)
      get :index
    end
    
    should_respond_with :redirect
    should_redirect_to 'unauthorized_path'
    should_set_the_flash_to /You are not authorized/

  end
  
  context "Logged in as employee" do
    setup do
      @controller.stubs(:current_privileges).returns(['read events'])
      ActionView::Base.any_instance.stubs(:current_privileges).returns(['read events'])
      @controller.stubs(:current_user).returns(@employee)
      ActionView::Base.any_instance.stubs(:current_user).returns(@employee)
    end
    
    context "get events index" do

      setup do
        get :index
      end
      
      should_respond_with :success
      should_render_template "events/index.html.haml"
      should_assign_to :urgent
      should_assign_to :approval
      should_assign_to :informational
    end
    
    context "mark event as seen" do
      
      setup do
        post :mark_as_seen, :id => @event.id        
      end
      
      should_respond_with :redirect
      should_redirect_to 'unauthorized_path'
      should_set_the_flash_to /You are not authorized/

    end
  end
  
  context "Logged in as manager" do
    setup do
      @controller.stubs(:current_privileges).returns(['read events', 'update events'])
      ActionView::Base.any_instance.stubs(:current_privileges).returns(['read events', 'update events'])
      @controller.stubs(:current_user).returns(@owner)
      ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
    end
    
    context "get events index" do

      setup do
        get :index
      end
      
      should_respond_with :success
      should_render_template "events/index.html.haml"
      should_assign_to :urgent
      should_assign_to :approval
      should_assign_to :informational
    end
    
    context "mark event as seen" do
      
      setup do
        post :mark_as_seen, :id => @event.id        
      end
      
      should_respond_with :redirect
      # should_redirect_to 'dashboard_path'
    end
  end
end
