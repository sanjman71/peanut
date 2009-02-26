require 'test/test_helper'
require 'test/factories'

class SubscriptionTest < ActiveSupport::TestCase
  should_require_attributes :company_id, :user_id, :plan_id, :start_billing_at
  should_have_many          :payments
  
  def setup
    @company      = Factory(:company)
    @user         = Factory(:user)
  end
  
  context "monthly subscription starting today" do
    setup do
      @monthly_plan = Factory(:monthly_plan, :start_billing_in_time_amount => 0, :start_billing_in_time_unit => "days")
      @subscription = Subscription.create(:company => @company, :user => @user, :plan => @monthly_plan)
    end

    should_change "Subscription.count", :by => 1
    
    should "start with subscription in initialized state" do
      assert @subscription.initialized?
    end
    
    context "authorize with a valid credit card" do
      setup do
        @credit_card  = credit_card(:number => '1')
        @payment      = @subscription.authorize(@credit_card)
        @subscription.reload
      end
      
      should "have a 1 total payment" do
        assert_equal [@payment], @subscription.payments
      end
    
      should "have a 1 authorized payment" do
        assert_equal [@payment], @subscription.payments.authorized
      end
      
      should "change subscription to authorized state" do
        assert @subscription.authorized?
      end
      
      should "have next billing date == today" do
        assert_equal Time.now.beginning_of_day, @subscription.next_billing_at
      end
      
      context "bill subscription" do
        setup do
          @paid_payment = @subscription.bill(@credit_card)
          @subscription.reload
        end
    
        should "change subscription to active state" do
          assert @subscription.active?
        end
        
        should "update last, next billing dates" do
          assert_equal Date.today, @subscription.last_billing_at.to_date
          assert_equal Date.today + 1.month, @subscription.next_billing_at.to_date
        end
    
        should "have a 2 total payment" do
          assert_equal [@payment, @paid_payment], @subscription.payments
        end
    
        should "have a 1 paid payment" do
          assert_equal [@paid_payment], @subscription.payments.paid
        end
        
        should "raise exception if billed again" do
          assert_raise SubscriptionError do
            @subscription.bill(@credit_card)
          end
        end
      end
    end

    context "authorize with an valid credit card" do
      setup do
        @credit_card  = credit_card(:number => '2')
        @payment      = @subscription.authorize(@credit_card)
      end
      
      should "have 1 total payment" do
        assert_equal [@payment], @subscription.payments
      end
      
      should "leave subscription in initialized state" do
        assert @subscription.initialized?
      end
    
      should "have no next billing date" do
        assert_equal nil, @subscription.next_billing_at
      end
      
      should "have subscription errors" do
        assert !@subscription.errors.empty?
        assert_equal 'Credit card is invalid', @subscription.errors.on_base
      end
    end
  end
  
  context "montly subscription starting in 1 month" do
    setup do
      @monthly_plan = Factory(:monthly_plan)
      @subscription = Subscription.create(:company => @company, :user => @user, :plan => @monthly_plan)
    end
  
    should_change "Subscription.count", :by => 1
    
    should "start with subscription in initialized state" do
      assert @subscription.initialized?
    end
    
    context "authorize with a valid credit card" do
      setup do
        @credit_card  = credit_card(:number => '1')
        @payment      = @subscription.authorize(@credit_card)
      end
      
      should "have 1 total payment" do
        assert_equal [@payment], @subscription.payments
      end
  
      should "have 1 authorized payment" do
        assert_equal [@payment], @subscription.payments.authorized
      end
      
      should "leave subscription in authorized state" do
        assert @subscription.authorized?
      end
      
      should "have next billing date in 1 month" do
        assert_equal Time.now.beginning_of_day + 1.month, @subscription.next_billing_at
      end
    
      should "should raise subscription error if billed again" do
        assert_raise SubscriptionError do
          @subscription.bill(@credit_card)
        end
      end
    end
  end
  
end