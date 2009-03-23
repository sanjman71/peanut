require 'test/test_helper'
require 'test/factories'

class CustomersControllerTest < ActionController::TestCase

  # generic users controller routes
  should_route :get,  '/customers/new', :controller => 'users', :action => 'new', :type => 'customer'
  should_route :post, '/customers/create', :controller => 'users', :action => 'create', :type => 'customer'
  should_route :get,  '/customers/1/edit', :controller => 'users', :action => 'edit', :id => '1', :type => 'customer'
  should_route :put,  '/customers/1', :controller => 'users', :action => 'update', :id => '1', :type => 'customer'

  # customers controller routes
  should_route :get,  '/customers/1', :controller => 'customers', :action => 'show', :id => '1'

  def setup
    @controller   = CustomersController.new
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # create customer role
    @role         = Badges::Role.create(:name=>"customer")
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
  end
  
  context "search an empty customers database with an empty search" do
    context "and without 'read users' privilege" do
      setup do
        # stub privileges
        @controller.stubs(:current_privileges).returns([])
        get :index
      end
      
      should_respond_with :redirect
      should_redirect_to 'unauthorized_path'
    end
    
    context "and with 'read users' privilege" do
      setup do
        # stub privileges
        @controller.stubs(:current_privileges).returns(['read users'])
        # stub current_user method
        @controller.stubs(:current_user).returns(@owner)
        # stub has_role? method
        @owner.stubs(:has_role?).returns(true)
        get :index
      end

      should_respond_with :success
      should_render_template 'customers/index.html.haml'
      should_not_set_the_flash
      should_assign_to :customers, :search_text
      should_not_assign_to :search
    
      should "find no customers" do
        assert_equal [], assigns(:customers)
      end
    
      should "have search text 'No Customers'" do
        assert_equal "No Customers", assigns(:search_text)
      end
    end
  end
  
  context "search non-empty customer database" do
    setup do
      # create customer with a valid appointment
      @customer     = Factory(:user, :name => 'Booty Licious')
      @johnny       = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut      = Factory(:work_service, :name => "Haircut", :companies => [@company], :price => 1.00)
      @appointment  = Factory(:appointment_today, :company => @company, :customer => @customer, :schedulable => @johnny, :service => @haircut)
      assert_valid @appointment
    end

    context "with an ajax search for 'boo' with 'read users' privilege" do
      setup do
        # stub privileges
        @controller.stubs(:current_privileges).returns(['read users'])
        # stub current_user method
        @controller.stubs(:current_user).returns(@owner)
        # stub has_role? method
        @owner.stubs(:has_role?).returns(true)
        xhr :get, :index, :format => 'js', :search => 'boo'
      end
    
      should_respond_with :success
      should_render_template 'customers/index.js.rjs'
      should_respond_with_content_type "text/javascript"
      should_not_set_the_flash
      should_assign_to :customers, :search, :search_text

      should "find customer" do
        assert_equal [@customer], assigns(:customers)
        # assert_equal "", @response.body
      end

      should "have a search value" do
        assert_equal 'boo', assigns(:search)
      end
      
      should "have search text" do
        assert_equal "Customers matching 'boo'", assigns(:search_text)
      end
      
    end
  end

  context "show customer" do
    setup do
      # create customer
      @customer = Factory(:user, :name => 'Customer')
    end

    context "with no notes" do
      setup do
        get :show, :id => @customer.id
      end
      
      should_respond_with :success
      should_render_template 'customers/show.html.haml'
      should_respond_with_content_type "text/html"
      should_not_set_the_flash
      should_assign_to :customer, :note, :notes
    
      should "find customer" do
        assert_equal @customer, assigns(:customer)
        assert_equal [], assigns(:notes)
      end
    end
    
    context "with notes" do 
      setup do
        # create customer note
        @customer.notes.push(Note.new(:comment => "Note 1"))
        @notes = @customer.notes
        get :show, :id => @customer.id
      end

      should_respond_with :success
      should_render_template 'customers/show.html.haml'
      should_respond_with_content_type "text/html"
      should_not_set_the_flash
      should_assign_to :customer, :note, :notes
    
      should "find customer and notes" do
        assert_equal @customer, assigns(:customer)
        assert_equal @notes, assigns(:notes)
      end
    end
    
  end
end
