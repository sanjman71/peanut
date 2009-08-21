require 'test/test_helper'

class ActionView::Base
  include PlansHelper
  include LocationsHelper
end

class CompaniesControllerTest < ActionController::TestCase     

  # Make sure we are routing the convenience routes
  # TODO - ideally we should not route www.peanut.com/show in this way - we should only route valid company subdomains. Don't know how to check this
  should_route :get, '/edit', :controller => 'companies', :action => 'edit'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    # create company
    @owner        = Factory(:user, :name => "Owner")
    @user         = Factory(:user, :name => "Joe Soap")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    # owner is company manager
    @owner.grant_role('company manager', @company)
    # stub current company method
    @controller.stubs(:current_company).returns(@company)
    # create admin user
    @admin        = Factory(:user, :name => "Admin")
    @admin.grant_role('admin')
    # create regular user
    @user         = Factory(:user, :name => "User")
  end
  
  context "show companies" do
    context "without 'read companies' privilege" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :index
      end
  
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  
    context "with 'read companies' privileges" do
      setup do
        @controller.stubs(:current_user).returns(@admin)
        get :index
      end
  
      should_respond_with :success
      should_render_template 'companies/index.html.haml'
      should_not_set_the_flash
      should_assign_to :companies
    end
  end

  context "edit company" do
    context "as the company owner" do
      setup do
        @controller.stubs(:current_user).returns(@owner)
        get :edit, :id => @company.id
      end

      should_respond_with :success
      should_render_template 'companies/edit.html.haml'
      
      context "add a logo" do
        setup do
          @image1   = File.new(File.join(File.dirname(__FILE__), "..", "fixtures", "Kunst-Eichel.jpg"), 'rb')
          @image2   = File.new(File.join(File.dirname(__FILE__), "..", "fixtures", "rose.jpg"), 'rb')
          @pdf      = File.new(File.join(File.dirname(__FILE__), "..", "fixtures", "walnut_places.pdf"), 'rb')
          @bigimage = File.new(File.join(File.dirname(__FILE__), "..", "fixtures", "crude_awakening.jpg"), 'rb')
          
          put :update, :id => @company.id, :company => {:logo_attributes => {:image => @image1}}
          @company.reload
        end
        
        # Delete the files when we're finished
        teardown { @company.logo.destroy unless @company.logo.nil? }
        
        should "have a logo with thumbnails" do
          assert_not_nil @company.logo
          assert_not_nil @company.logo.image
          assert_not_nil @company.logo.image.url
          assert_not_nil @company.logo.image.url(:large)
          assert_not_nil @company.logo.image.url(:medium)
          assert_not_nil @company.logo.image.url(:small)
        end
        
        should "have a logo file in the filesystem" do
          assert File.exists?(@company.logo.image.path)
        end
        
        context "delete the logo" do
          setup do
            @imagepath = @company.logo.image.path
            put :update, :id => @company.id, :company => {:logo_attributes => {:_delete => "1", :id => @company.logo.id}}
            @company.reload
          end
          
          should "not have a logo" do
            assert_nil @company.logo
          end
        
          should "not have a logo file in the filesystem" do
            assert !File.exists?(@imagepath)
          end
        end
        
        context "udpate the logo" do
          setup do
            @image1path = @company.logo.image.path
            put :update, :id => @company.id, :company => {:logo_attributes => {:id => @company.logo.id, :image => @image2}}
            @company.reload
          end
        
          should "have a logo with thumbnails" do
            assert_not_nil @company.logo
            assert_not_nil @company.logo.image
            assert_not_nil @company.logo.image.url
            assert_not_nil @company.logo.image.url(:large)
            assert_not_nil @company.logo.image.url(:medium)
            assert_not_nil @company.logo.image.url(:small)
          end
        
          should "have a new logo file in the filesystem" do
            assert File.exists?(@company.logo.image.path)
          end
        
          should "not have the old logo file in the filesystem" do
            assert !File.exists?(@image1path)
          end
        end
      end
    end

    context "as a regular user" do
      setup do
        @controller.stubs(:current_user).returns(@user)
        get :edit, :id => @company.id
      end
    
      should_respond_with :redirect
      should_redirect_to('unauthorized_path') { unauthorized_path }
    end
  end
  
end
