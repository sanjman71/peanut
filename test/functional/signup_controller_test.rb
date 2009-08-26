require 'test/test_helper'
require 'test/factories'

class SignupControllerTest < ActionController::TestCase

  should_route :get,  '/signup/1', :controller => 'signup', :action => 'new', :plan_id => '1'
  
  def setup
    @controller   = SignupController.new
    # create plans
    @free_plan    = Factory(:free_plan)
    @monthly_plan = Factory(:monthly_plan)
    # create promotion
    @promotion    = Promotion.create(:code => "free5", :uses_allowed => 5, :discount => 10.0, :units => 'dollars')
  end

  context "signup page" do
    setup do
      get :index
    end

    should_respond_with :success
    should_render_template 'signup/index.html.haml'
  end

  context "signup new" do
    context "for the free plan" do
      setup do
        get :new, :plan_id => @free_plan.id
      end

      should_assign_to :company, :user, :subscription
      should_assign_to(:plan) { @free_plan }
      should_not_assign_to(:promotion)
      should_assign_to(:price) { 0 }

      should_respond_with :success
      should_render_template 'signup/new.html.haml'
    end
    
    context "using free promotion" do
      setup do
        get :new, :plan_id => @monthly_plan.id, :promo => 'free5'
      end

      should_assign_to :company, :user, :subscription, :promotion
      should_assign_to(:plan) { @monthly_plan }
      should_assign_to(:price) { 0 }
 
      should_respond_with :success
      should_render_template 'signup/new.html.haml'
    end
  end

  context "signup create" do
    context "for the free plan" do
      setup do
        post :create, 
             {:user => {:name => 'Peanut Manager', :password => 'foo', :password_confirmation => 'foo', :email => 'walnut@jarna.com'},
              :company => {:name=>"Peanut", :subdomain=>"peanut", :terms=>"1", :time_zone=>"Central Time (US & Canada)"},
              :plan_id => @free_plan.id
              }
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("Company.count", :by => 1) { Company.count }
      should_change("Subscription.count", :by => 1) { Subscription.count }
      
      should_assign_to :company, :user
      should_assign_to(:plan) { @free_plan }

      should "create user with roles 'user manager' on user" do
        @user = User.find_by_email('walnut@jarna.com')
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end

      should "create user with roles 'company manager', 'company provider' on company" do
        @company = Company.find_by_name('Peanut')
        @user    = User.find_by_email('walnut@jarna.com')
        assert_equal ['company manager', 'company provider'], assigns(:user).roles_on(@company).collect(&:name).sort
      end

      should "create company with user as a provider" do
        @company = Company.find_by_name('Peanut')
        @user    = User.find_by_email('walnut@jarna.com')
        assert_equal [@user], @company.providers
      end

      should_respond_with :redirect
      should_redirect_to('peanut login page') { login_path(:subdomain => "peanut") }
    end

    context "using free promotion" do
      setup do
        post :create, 
             {:user => {:name => 'Peanut Manager', :password => 'foo', :password_confirmation => 'foo', :email => 'walnut@jarna.com'},
              :company => {:name=>"Peanut", :subdomain=>"peanut", :terms=>"1", :time_zone=>"Central Time (US & Canada)"},
              :plan_id => @monthly_plan.id, :promo => 'free5'
              }
      end
      
      should_change("User.count", :by => 1) { User.count }
      should_change("Company.count", :by => 1) { Company.count }
      should_change("Subscription.count", :by => 1) { Subscription.count }
      
      should_assign_to :company, :user, :promotion
      should_assign_to(:plan) { @monthly_plan }
      
      should "create user with roles 'user manager' on user" do
        @user = User.find_by_email('walnut@jarna.com')
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end

      should "create user with roles 'company manager', 'company provider' on company" do
        @company = Company.find_by_name('Peanut')
        @user    = User.find_by_email('walnut@jarna.com')
        assert_equal ['company manager', 'company provider'], assigns(:user).roles_on(@company).collect(&:name).sort
      end

      should "create company with user as a provider" do
        @company = Company.find_by_name('Peanut')
        @user    = User.find_by_email('walnut@jarna.com')
        assert_equal [@user], @company.providers
      end

      should_respond_with :redirect
      should_redirect_to('peanut login page') { login_path(:subdomain => "peanut") }
    end
  end
  
end