require 'test/test_helper'
require 'test/factories'

class CustomersControllerTest < ActionController::TestCase

  def setup
    stub_subdomain
  end
  
  context "search an empty customers database with an empty search" do
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
  
  context "search non-empty customer database" do
    setup do
      # create customer with a valid appointment
      @customer     = Factory(:customer, :name => 'Booty Licious')
      @johnny       = Factory(:person, :name => "Johnny", :companies => [@company])
      @haircut      = Factory(:work_service, :name => "Haircut", :company => @company, :price => 1.00)
      @appointment  = Factory(:appointment_today, :company => @company, :customer => @customer, :resource => @johnny, :service => @haircut)
      assert_valid @appointment
    end

    context "with an ajax search for 'boo'" do
      setup do
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
      @customer = Factory(:customer, :name => 'Customer')
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
