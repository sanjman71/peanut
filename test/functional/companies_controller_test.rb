require File.dirname(__FILE__) + '/../test_helper'

class CompaniesControllerTest < ActionController::TestCase     

  # Make sure we are routing the convenience routes
  # TODO - ideally we should not route www.peanut.com/show in this way - we should only route valid company subdomains. Don't know how to check this
  should_route :get, 'show', :controller => 'companies', :action => 'show'
  should_route :get, 'edit', :controller => 'companies', :action => 'edit'

  def setup
    @controller   = CompaniesController.new
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # stub current company method
    @controller.stubs(:current_company).returns(@company)    
  end
  
  context "" do
    setup do
      get :index
    end

    should_respond_with :success
    should_render_template 'customers/index.html.haml'
    should_not_set_the_flash
    should_assign_to :customers, :search_text
    should_not_assign_to :search
    
    should "find 0 customers" do
      assert_equal [], assigns(:customers)
    end
    
    should "have search text" do
      assert_equal "No Customers", assigns(:search_text)
    end
  end

  
  

end