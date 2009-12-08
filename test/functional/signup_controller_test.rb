require 'test/test_helper'
require 'test/factories'

class SignupControllerTest < ActionController::TestCase

  should_route :get,  '/signup/1', :controller => 'signup', :action => 'new', :plan_id => '1'
  
  def setup
    @controller   = SignupController.new
    # create plans
    @free_plan    = Factory(:free_plan)
    @monthly_plan = Factory(:monthly_plan)
    @basic_plan   = Factory(:monthly_plan, :name => 'Basic')
    # create free promotion
    @promotion    = Promotion.create(:code => "free5", :uses_allowed => 5, :discount => 100.0, :units => 'percent')
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

  context "signup check" do
    context "using a promotion with no remaining uses" do
      setup do
        Promotion.any_instance.stubs(:remaining).returns(0)
        post :check, :promotion => {:code => 'free5'}
      end

      should_assign_to(:promotion) { @promotion}
      should_redirect_to('signup beta page') { signup_beta_path }
    end

    context "for a promotion with remaining uses" do
      setup do
        post :check, :promotion => {:code => 'free5'}
      end

      should_assign_to(:promotion) { @promotion}
      should_redirect_to('signup page') { signup_plan_path(@basic_plan, :promo =>'free5') }
    end
  end

  context "signup create" do
    context "for the free plan" do
      setup do
        post :create, 
             {:user => {:name => 'Peanut Manager', :password => 'foo', :password_confirmation => 'foo', 
                        :email_addresses_attributes => [{:address => 'manager@walnut.com'}]},
              :company => {:name=>"Peanut", :subdomain=>"peanut", :terms=>"1", :time_zone=>"Central Time (US & Canada)"},
              :plan_id => @free_plan.id
              }
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("Company.count", :by => 1) { Company.count }
      should_change("Subscription.count", :by => 1) { Subscription.count }

      should_assign_to :company, :user
      should_assign_to(:plan) { @free_plan }
      should_assign_to(:price) { 0.0 }
      should_not_assign_to(:credit_card)
      should_not_assign_to(:payment)

      should "create user with roles 'user manager' on user" do
        @user = User.with_email('manager@walnut.com').first
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end

      should "create user with roles 'company manager', 'company provider' on company" do
        @company = Company.find_by_name('Peanut')
        @user    = User.with_email('manager@walnut.com').first
        assert_equal ['company manager', 'company provider'], assigns(:user).roles_on(@company).collect(&:name).sort
      end

      should "create company with user as a provider" do
        @company = Company.find_by_name('Peanut')
        @user    = User.with_email('manager@walnut.com').first
        assert_equal [@user], @company.user_providers
      end

      should "create subscription in 'active' state" do
        @company      = Company.find_by_name("Peanut")
        @subscription = @company.subscription
        assert_equal 'active', @subscription.state
      end

      should_respond_with :redirect
      should_redirect_to('peanut login page') { login_path(:subdomain => "peanut") }
    end

    context "for a paid plan using free promotion" do
      setup do
        post :create, 
             {:user => {:name => 'Peanut Manager', :password => 'foo', :password_confirmation => 'foo', 
                        :email_addresses_attributes => [{:address => 'manager@walnut.com'}]},
              :company => {:name=>"Peanut", :subdomain=>"peanut", :terms=>"1", :time_zone=>"Central Time (US & Canada)"},
              :plan_id => @monthly_plan.id, :promo => 'free5'
              }
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("Company.count", :by => 1) { Company.count }
      should_change("Subscription.count", :by => 1) { Subscription.count }

      should_assign_to(:company, :user, :promotion, :subscription)
      should_assign_to(:plan) { @monthly_plan }
      should_assign_to(:price) { 0.0 }
      should_not_assign_to(:credit_card)
      should_not_assign_to(:payment)

      should "create user with roles 'user manager' on user" do
        @user = User.with_email('manager@walnut.com').first
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end

      should "create user with roles 'company manager', 'company provider' on company" do
        @company = Company.find_by_name('Peanut')
        @user    = User.with_email('manager@walnut.com').first
        assert_equal ['company manager', 'company provider'], @user.roles_on(@company).collect(&:name).sort
      end

      should "create company with user as a provider" do
        @company = Company.find_by_name('Peanut')
        @user    = User.with_email('manager@walnut.com').first
        assert_equal [@user], @company.user_providers
      end

      should "create subscription in 'active' state" do
        @company      = Company.find_by_name("Peanut")
        @subscription = @company.subscription
        assert_equal 'active', @subscription.state
      end

      should_change("promotion redemptions", :by => 1) { PromotionRedemption.count }

      should "link promotion redemption to subscription" do
        @company      = Company.find_by_name("Peanut")
        @redemption   = @promotion.promotion_redemptions.first
        @subscription = @company.subscription
        assert_equal @subscription, @redemption.redeemer
      end

      should_redirect_to('peanut login page') { login_path(:subdomain => "peanut") }
    end
  end
  
end