require File.dirname(__FILE__) + '/../test_helper'
require 'test/factories'

class ActionView::Base
  include PlansHelper
  include LocationsHelper
end

class CompaniesControllerTest < ActionController::TestCase     

  # Make sure we are routing the convenience routes
  # TODO - ideally we should not route www.peanut.com/show in this way - we should only route valid company subdomains. Don't know how to check this
  should_route :get, 'show', :controller => 'companies', :action => 'show'
  should_route :get, 'edit', :controller => 'companies', :action => 'edit'

  def setup
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @user         = Factory(:user, :name => "Joe Soap")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
  end
  
  context "do not show companies index without privileges" do
    setup do
      @controller.stubs(:current_privileges).returns([])
      get :index
    end

    should_respond_with :redirect
    should_redirect_to 'unauthorized_path'
  end
  
  context "show companies index with privileges" do
    
    setup do
      ActionView::Base.any_instance.stubs(:current_user).returns(@owner)
      ActionView::Base.any_instance.stubs(:global_flash?).returns(true)
      @controller.stubs(:current_privileges).returns(['read companies'])
      get :index
    end
  
    should_respond_with :success
    should_render_template 'companies/index.html.haml'
    should_not_set_the_flash
    should_assign_to :companies
  end
  
  context "working with a single company" do

    setup do
      # stub current company method
      ActionView::Base.any_instance.stubs(:current_company).returns(@company)
      ActionView::Base.any_instance.stubs(:global_flash?).returns(true)
    end

    context "as a regular user" do
      setup do
        ActionView::Base.any_instance.stubs(:current_user).returns(@user)
        @controller.stubs(:current_privileges).returns([])      
      end
      
      context "edit company" do
        setup do
          get :edit, :id => @company.id
        end
        
        should_respond_with :redirect
        should_redirect_to 'unauthorized_path'
      end
    end
    
    context "as the company owner" do
      setup do
        ActionView::Base.any_instance.stubs(:current_user).returns(@user)
        @controller.stubs(:current_privileges).returns(['update companies'])      
      end
      
      context "edit company" do
        setup do
          get :edit, :id => @company.id
        end
        
        should_respond_with :success
        should_render_template 'companies/edit.html.haml'
        
      end
    end
    
  end

end
