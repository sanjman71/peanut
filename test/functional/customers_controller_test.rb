require 'test/test_helper'

class CustomersControllerTest < ActionController::TestCase

  # generic users controller routes
  should_route :get,  '/customers/new', :controller => 'users', :action => 'new', :role => 'company customer'
  should_route :post, '/customers/create', :controller => 'users', :action => 'create', :role => 'company customer'
  should_route :get,  '/customers/1/edit', :controller => 'users', :action => 'edit', :id => '1', :role => 'company customer'
  should_route :put,  '/customers/1', :controller => 'users', :action => 'update', :id => '1', :role => 'company customer'

  # customers controller routes
  should_route :get,  '/customers', :controller => 'customers', :action => 'index'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    # create user
    @user         = Factory(:user, :name => "User")
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
  end

  context "search without 'read users' privilege" do
    setup do
      @controller.stubs(:current_user).returns(@user)
      get :index
    end
  
    should_redirect_to('unauthorized_path') { unauthorized_path }
  end

  context "search empty customers database with an empty search" do
    setup do
      @controller.stubs(:current_user).returns(@owner)
      get :index
    end

    should_assign_to(:customers) { [] }
    should_assign_to(:paginate) { true }
    should_not_assign_to :search, :search_text

    should_not_set_the_flash
    should_respond_with :success
    should_render_template 'customers/index.html.haml'
  end

  context "search non-empty customer database" do
    setup do
      # create customer with a valid appointment
      @customer     = Factory(:user, :name => 'Booty Licious')
      @johnny       = Factory(:user, :name => "Johnny")
      @company.user_providers.push(@johnny)
      @haircut      = Factory.build(:work_service, :name => "Haircut", :price => 1.00)
      @company.services.push(@haircut)
      @haircut.user_providers.push(@johnny)
      @appointment  = Factory(:appointment_today, :company => @company, :customer => @customer, :provider => @johnny, :service => @haircut)
      assert @appointment.valid?
    end

    context "all customers as company manager" do
      setup do
        # as company manager
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end

      should_respond_with :success
      should_render_template 'customers/index.html.haml'
      should_respond_with_content_type "text/html"
      should_not_set_the_flash
      should_assign_to(:customers) { [@customer] }
      should_not_assign_to(:search)
      should_not_assign_to(:search_text)
      should_assign_to(:paginate) { false }

      should "have customer edit link" do
        assert_select "a.admin.edit.customer", 1
        assert_select "a[href='/customers/%s/edit']" % @customer.id, 1
      end

      should "not have customer sudo link" do
        assert_select "a.admin.customer.sudo", 0
      end
    end

    context "with a ajax js search for 'boo' as company manager" do
      setup do
        # as company manager
        @controller.stubs(:current_user).returns(@owner)
        xhr :get, :index, :format => 'js', :q => 'boo'
      end

      should_respond_with :success
      should_render_template 'customers/index.js.rjs'
      should_respond_with_content_type "text/javascript"
      should_not_set_the_flash
      should_assign_to(:customers) { [@customer] }
      should_assign_to(:search) { 'boo' }
      should_assign_to(:search_text) { "Customers matching 'boo'" }
      should_assign_to(:paginate) { false }

      # SK TODO: find out why these links are not shown in xhr tests but they show up in regular gets
      # should "have customer edit link" do
      #   assert_select "a.admin.edit.customer", 1
      #   assert_select "a[href='/customers/%s/edit']" % @customer.id, 1
      # end

      should "not have customer sudo link" do
        assert_select "a.admin.customer.sudo", 0
      end
    end
  end

  # context "show customer" do
  #   setup do
  #     # create customer
  #     @customer = Factory(:user, :name => 'Customer')
  #   end
  # 
  #   context "with no notes" do
  #     setup do
  #       get :show, :id => @customer.id
  #     end
  #     
  #     should_respond_with :success
  #     should_render_template 'customers/show.html.haml'
  #     should_respond_with_content_type "text/html"
  #     should_not_set_the_flash
  #     should_assign_to :customer, :note, :notes
  #   
  #     should "find customer" do
  #       assert_equal @customer, assigns(:customer)
  #       assert_equal [], assigns(:notes)
  #     end
  #   end
  #   
  #   context "with notes" do 
  #     setup do
  #       # create customer note
  #       @customer.notes.push(Note.new(:comment => "Note 1"))
  #       @notes = @customer.notes
  #       get :show, :id => @customer.id
  #     end
  # 
  #     should_respond_with :success
  #     should_render_template 'customers/show.html.haml'
  #     should_respond_with_content_type "text/html"
  #     should_not_set_the_flash
  #     should_assign_to :customer, :note, :notes
  #   
  #     should "find customer and notes" do
  #       assert_equal @customer, assigns(:customer)
  #       assert_equal @notes, assigns(:notes)
  #     end
  #   end
  # end
end
