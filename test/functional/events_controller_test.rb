require 'test/test_helper'
require 'test/factories'

class EventsControllerTest < ActionController::TestCase

  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # make owner the company manager
    @owner.grant_role('company manager', @company)
    @owner.grant_role('company employee', @company)
    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)
    @controller.stubs(:current_privileges).returns(['read events'])
    ActionView::Base.any_instance.stubs(:current_privileges).returns(['read events'])
    @controller.stubs(:current_user).returns(@owner)
    ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
    
  end
  
  context "Create an event without a type" do
    setup do
      post :create, :message => "test event"
    end
    
    should_respond_with :redirect
    # should_redirect_to 'events_path(:subdomain => "www")'
    should_set_the_flash_to /Problem creating event/

  end
  
  context "Create an event" do
    
    setup do
      post :create, :message => "test event", :etype => Event::URGENT, :company_id => @company.id
    end
    
    should_respond_with :redirect
    # should_redirect_to 'events_path(:subdomain => "www")'
    
    context "view the event index" do
      setup do
        get :index
      end
      
      should_respond_with :success
      should_render_template "events/index.html.haml"
      should_assign_to :urgent
      should_assign_to :approval
      should_assign_to :informational
      
    end
    
  end
  
end
