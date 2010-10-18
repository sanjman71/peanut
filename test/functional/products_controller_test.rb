require 'test_helper'

# class ProductsControllerTest < ActionController::TestCase
# 
#   def setup
#     @controller   = ProductsController.new
#     # create a valid company
#     @owner        = Factory(:user, :name => "Owner")
#     @monthly_plan = Factory(:monthly_plan)
#     @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
#     @company      = Factory(:company, :subscription => @subscription)
#     # stub current company method
#     @controller.stubs(:current_company).returns(@company)
#   end
# 
#   context "create product" do
#     context "without privilege ['create products']" do
#       setup do
#         @controller.stubs(:current_privileges).returns([])
#         xhr :post, :create, :product => {:name => "", :price => "0", :inventory => "0"}
#       end
#       
#       should_redirect_to("unauthorized_path") { unauthorized_path }
#     end
#     
#     context "with a blank name" do
#       setup do
#         @controller.stubs(:current_privileges).returns(["create products"])
#         xhr :post, :create, :product => {:name => "", :price => "0", :inventory => "0"}
#       end
#     
#       should_respond_with :success
#       should_render_template 'products/create.js.rjs'
#       should_respond_with_content_type "text/javascript"
#       should_assign_to :product
#       should_set_the_flash_to "Could not create product"
#       should_assign_to(:error) { true }
#       should_not_change("Product.count") { Product.count }
#     end
#     
#     context "with a valid name" do
#       setup do
#         @controller.stubs(:current_privileges).returns(["create products"])
#         xhr :post, :create, :product => {:name => "Pomade", :price => "0", :inventory => "0"}
#       end
#     
#       should_respond_with :success
#       should_render_template 'products/create.js.rjs'
#       should_respond_with_content_type "text/javascript"
#       should_assign_to :product
#       should_not_assign_to :error
#       should_not_set_the_flash
#       should_change("Product.count", :by => 1) { Product.count }
#       
#       should "be a rjs redirect to product edit" do
#         assert_equal edit_product_path(assigns(:product)), assigns(:redirect_path)
#         assert_match /window.location.href/, @response.body
#         assert_match /#{edit_product_path(assigns(:product))}/, @response.body
#         @product = assigns(:product)
#       end
#     end
#   end
# 
#   context "edit a new product" do
#     setup do 
#       # create product first, as it would be from the create form
#       @shampoo = Factory(:product, :name => 'Shampoo', :inventory => 0, :price => 0, :company => @company)
#     end
#     
#     context "with privilege ['update products']" do
#       setup do
#         @controller.stubs(:current_privileges).returns(["update products"])
#         get :edit, :id => @shampoo
#       end
# 
#       should_respond_with :success
#       should_render_template 'products/edit.html.haml'
#       should_respond_with_content_type "text/html"
#     end
#   
#     context "without privilege ['update products']" do
#       setup do
#         @controller.stubs(:current_privileges).returns([])
#         get :edit, :id => @shampoo
#       end
#       
#       should_redirect_to("unauthorized_path") { unauthorized_path }
#     end
#   end
#   
#   context "show all products" do
#     context "without privilege ['read products']" do
#       setup do
#         @controller.stubs(:current_privileges).returns([])
#         get :index
#       end
#       
#       should_redirect_to("unauthorized_path") { unauthorized_path }
#     end
#     
#     context "with privilege ['read products'], but not ['create products']" do
#       setup do
#         @controller.stubs(:current_privileges).returns(["read products"])
#         get :index
#       end
#       
#       should_respond_with :success
#       
#       should "not show add products form" do
#         assert_select "form#new_product_form", 0
#       end
#     end
#   
#     context "with privilege ['read products', 'create products']" do
#       setup do
#         @controller.stubs(:current_privileges).returns(["read products", "create products"])
#         get :index
#       end
#       
#       should_respond_with :success
#       
#       should "show add products form" do
#         assert_select "form#new_product_form", 1
#       end
#     end
#     
#     context "on an empty database" do 
#       setup do
#         @controller.stubs(:current_privileges).returns(["read products"])
#         get :index
#       end
#   
#       should_respond_with :success
#       should_render_template 'products/index.html.haml'
#       should_not_set_the_flash
#     
#       should "not find any products" do
#         assert_equal [], assigns(:products)
#       end
#     end
#     
#     context "on a database with 1 product" do
#       setup do
#         @controller.stubs(:current_privileges).returns(["read products"])
#         # create product first
#         @shampoo = Factory(:product, :name => 'Shampoo', :company => @company)
#         get :index
#       end
#   
#       should_respond_with :success
#       should_render_template 'products/index.html.haml'
#       should_not_set_the_flash
#   
#       should "find 1 product" do
#         assert_equal [@shampoo], assigns(:products)
#       end
#       
#       should "not show pagination links" do
#         assert_select 'div.pagination', false
#       end
#     end
#   end
# 
# end