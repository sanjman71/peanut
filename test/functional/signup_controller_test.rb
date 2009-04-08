require 'test/test_helper'
require 'test/factories'

class SignupControllerTest < ActionController::TestCase

  should_route :get,  '/signup/1', :controller => 'signup', :action => 'new', :id => '1'
  
  def setup
    @controller   = SignupController.new
    # create free plan
    @free_plan    = Factory(:free_plan)
  end
  
  context "signup" do
    context "for the free plan" do
      setup do
        post :create, 
             {:user => {:name => 'Walnut Manager', :password => 'foo', :password_confirmation => 'foo', :email => 'walnut@jarna.com'},
              :company => {:name=>"Peanut", :subdomain=>"peanut", :terms=>"1", :time_zone=>"Central Time (US & Canada)"},
              :plan_id => @free_plan.id
              }
      end

      should_change "User.count"
      should_change "Company.count"
      
      should_assign_to :company
      should_assign_to :user
      should_assign_to :plan, :equals => @free_plan
      
      should "create user with roles 'manager' and 'provider'" do
        assert_equal ['manager', 'provider'], assigns(:user).roles.collect(&:name).sort
      end
      
      should "create company with user as a schedulable" do
        assert_equal [assigns(:user)], assigns(:company).schedulables
      end
      
      should_respond_with :redirect
      should_redirect_to 'login_path(:subdomain => "peanut")'
    end
  end
  
end