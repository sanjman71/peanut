require 'test/test_helper'
require 'test/factories'

class FreeControllerTest < ActionController::TestCase

  # add free time for a specific resource
  should_route :get, 'users/1/free/block', :controller => "free", :action => 'new', :schedulable => "users", :id => "1", :style => "block"
  
  def setup
    @controller   = FreeController.new
    # create a valid company
    @johnny       = Factory(:user, :name => "Johnny")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @johnny, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription, :users => [@johnny])
    # create a work service
    @haircut      = Factory(:work_service, :name => "Haircut", :companies => [@company], :price => 1.00)
    # get company free service
    @free_service = @company.free_service
    # create customer
    @customer     = Factory(:user, :name => "Customer")
    # stub current company and location methods
    @controller.stubs(:current_company).returns(@company)
    @controller.stubs(:current_location).returns(Location.anywhere)
  end

end
