require 'test/test_helper'
require 'test/factories'

class ProductsControllerTest < ActionController::TestCase

  def setup
    stub_subdomain
  end

  context "create product" do
    context "without authorization" do
      
    end
    
    context "with a blank name" do
      setup do
        xhr :post, :create, :product => {:name => "", :price => "0", :inventory => "0"}
      end

      should_respond_with :success
      should_render_template 'products/create.js.rjs'
      should_respond_with_content_type "text/javascript"
      should_assign_to :product, :error_text
      should_assign_to :error, :equals => "true"
      should_not_change "Product.count"
            
      should "return error text" do
        assert_equal "Could not create product", assigns(:error_text)
      end
    end
    
    context "with a valid name" do
      setup do
        xhr :post, :create, :product => {:name => "Pomade", :price => "0", :inventory => "0"}
      end

      should_respond_with :success
      should_render_template 'products/create.js.rjs'
      should_respond_with_content_type "text/javascript"
      should_assign_to :product
      should_not_assign_to :error, :error_text
      should_not_set_the_flash
      should_change "Product.count", :by => 1
      
      should "be a rjs redirect to product edit" do
        assert_equal edit_product_path(assigns(:product)), assigns(:redirect_path)
        assert_match /window.location.href/, @response.body
        assert_match /#{edit_product_path(assigns(:product))}/, @response.body
        @product = assigns(:product)
      end
    end
  end

  context "edit a new product" do
    setup do 
      # create product first, as it would be from the create form
      @shampoo = Factory(:product, :name => 'Shampoo', :inventory => 0, :price => 0, :company => @company)
      get :edit, :id => @shampoo
    end
  
    should_respond_with :success
    should_render_template 'products/edit.html.haml'
    should_respond_with_content_type "text/html"
  end
  
  context "show all products" do
    context "on an empty database" do 
      setup do
        get :index
      end
  
      should_respond_with :success
      should_render_template 'products/index.html.haml'
      should_not_set_the_flash
    
      should "not find any products" do
        assert_equal [], assigns(:products)
      end
    end
    
    context "on a database with 1 product" do
      setup do
        # create product first
        @shampoo = Factory(:product, :name => 'Shampoo', :company => @company)
        get :index
      end
  
      should_respond_with :success
      should_render_template 'products/index.html.haml'
      should_not_set_the_flash
  
      should "find 1 product" do
        assert_equal [@shampoo], assigns(:products)
      end
      
      should "not show pagination links" do
        assert_select 'div.pagination', false
      end
    end
  end

end