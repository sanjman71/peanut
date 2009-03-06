require 'test/test_helper'
require 'test/factories'

class FreeControllerTest < ActionController::TestCase

  # add free time for a specific resource
  should_route :get, 'users/1/free/block', :controller => "free", :action => 'new', :schedulable => "users", :id => "1", :style => "block"
  
  def setup
    @controller   = FreeController.new
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # create company schedulable
    @company.schedulables.push(@owner)
    # find free service
    @free_service = @company.services.free.first
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
    @controller.stubs(:current_location).returns(Location.anywhere)
  end

  context "create appointment" do
    setup do
      post :create, 
           {:dates => ["20090201", "20090203"], :start_at => "0900", :end_at => "1100", :schedulable => "users/#{@owner.id}", :service_id => @free_service.id}
    end
    
    should_respond_with :success
    
  end

end
