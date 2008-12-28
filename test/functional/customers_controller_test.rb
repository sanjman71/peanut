require 'test/test_helper'
require 'test/factories'

class CustomersControllerTest < ActionController::TestCase

  def setup
    setup_subdomain
  end
  
  context "search customers on an empty db" do
    setup do
      get :index
    end

    should_respond_with :success
    should_render_template 'customers/index.html.haml'
    should_not_set_the_flash
    should_assign_to :customers, :search_text
    should_not_assign_to :search
    
    should "not find any customers with an empty search" do
      assert_equal [], assigns(:customers)
      assert_equal "No Customers", assigns(:search_text)
    end
  end
  
  context "search customers using a javascript request with 1 customer in the db" do
    setup do
      # stub search results
      @customer = Factory(:customer, :name => 'Customer')
      @company.stubs(:customers).returns(Customer)
      @company.stubs(:all).returns([@customer])
      xhr :get, :index, :format => 'js', :search => 'c'
    end

    should_respond_with :success
    should_render_template 'customers/index.js.rjs'
    should_respond_with_content_type "text/javascript"
    should_not_set_the_flash
    should_assign_to :customers, :search, :search_text
    
    should "find matching customers on a valid search" do
      assert_equal [@customer], assigns(:customers)
      assert_equal 'c', assigns(:search)
      assert_equal "Customers matching 'c'", assigns(:search_text)
      assert_match /text\/javascript/, @response.headers['type']
      # assert_equal "", @response.body
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
