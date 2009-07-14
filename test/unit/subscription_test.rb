require 'test/test_helper'
require 'test/factories'

class SubscriptionTest < ActiveSupport::TestCase
  should_validate_presence_of   :company_id, :user_id, :plan_id, :paid_count, :billing_errors_count
  should_have_many              :payments
  
  def setup
    @user = Factory(:user)
  end
  
  context "monthly subscription starting today" do
    setup do
      @monthly_plan = Factory(:monthly_plan, :start_billing_in_time_amount => 0, :start_billing_in_time_unit => "days")
      @subscription = Subscription.new(:user => @user, :plan => @monthly_plan)
      @company      = Factory(:company, :subscription => @subscription)
      assert_valid @subscription
    end

    should_change "Subscription.count", :by => 1
    
    should "start with subscription in initialized state" do
      assert @subscription.initialized?
    end
    
    should "have start billing at date initialized" do
      assert @subscription.start_billing_at
    end
    
    should "have no next billing at date" do
      assert_nil @subscription.next_billing_at
    end
    
    should "have 0 paid cycles and 0 billing errors" do
      assert_equal 0, @subscription.paid_count
      assert_equal 0, @subscription.billing_errors_count
    end
    
    context "authorize with a valid credit card" do
      setup do
        @credit_card        = credit_card(:number => '1')
        @authorization      = @subscription.authorize(@credit_card)
        @subscription.reload
      end
      
      should "have a 1 total payment" do
        assert_equal [@authorization], @subscription.payments
      end
    
      should "have a 1 authorized payment" do
        assert_equal [@authorization], @subscription.payments.authorized
      end
      
      should "change subscription to authorized state" do
        assert @subscription.authorized?
      end
      
      should "have next billing date == today" do
        assert_equal Time.now.utc.beginning_of_day, @subscription.next_billing_at
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
          assert_equal Time.now.utc.to_date, @subscription.last_billing_at.utc.to_date  # dates are easier to compare than timestamps
          assert_equal Time.now.utc.beginning_of_day + 1.month, @subscription.next_billing_at
        end
    
        should "have 2 total payments" do
          assert_equal [@authorization, @paid_payment], @subscription.payments
        end
    
        should "have 1 paid payment" do
          assert_equal [@paid_payment], @subscription.payments.paid
          assert_equal 1, @subscription.paid_count
        end
        
        should "have billing errors count == 0" do
          assert_equal 0, @subscription.billing_errors_count
        end
        
        should "raise exception if billed again" do
          assert_raise SubscriptionError do
            @subscription.bill(@credit_card)
          end
        end
        
        context "update credit card (after billing)" do
          
          setup do
            @credit_card2  = credit_card(:number => '1')
            @authorization2      = @subscription.authorize(@credit_card2)
            @subscription.reload
          end

          should "change subscription back to authorized state" do
            assert @subscription.authorized?
          end

          should "not change last, next billing dates" do
            assert_equal Time.now.utc.to_date, @subscription.last_billing_at.utc.to_date  # dates are easier to compare than timestamps
            assert_equal Time.now.utc.beginning_of_day + 1.month, @subscription.next_billing_at
          end

          should "have 3 total payments" do
            assert_equal [@authorization, @paid_payment, @authorization2], @subscription.payments
          end

          should "have 2 authorized payments" do
            assert_equal [@authorization, @authorization2], @subscription.payments.authorized
          end

          should "have billing errors count == 0" do
            assert_equal 0, @subscription.billing_errors_count
          end

        end
      end
      
      context "bill subscription with an invalid credit card" do
        setup do
          @bad_credit_card  = credit_card(:number => '2')
          @error_payment    = @subscription.bill(@bad_credit_card)
          @subscription.reload
        end

        should "set billing errors count to 1" do
          assert_equal 1, @subscription.billing_errors_count
        end
        
        should "leave subscription in authorized state" do
          assert @subscription.authorized?
        end
      end
      
      
      context "update credit card (after authorization and before billing)" do
        
        setup do
          @credit_card2  = credit_card(:number => '1')
          @authorization2      = @subscription.authorize(@credit_card2)
          @subscription.reload
        end

        should "keep subscription at authorized state" do
          assert @subscription.authorized?
        end

        should "have next billing date == today" do
          assert_equal Time.now.utc.beginning_of_day, @subscription.next_billing_at
        end

        should "have 2 total payments" do
          assert_equal [@authorization, @authorization2], @subscription.payments
        end

        should "have 2 authorized payments" do
          assert_equal [@authorization, @authorization2], @subscription.payments.authorized
        end

        should "have billing errors count == 0" do
          assert_equal 0, @subscription.billing_errors_count
        end

      end
      
    end

    context "authorize with an invalid credit card" do
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
      @subscription = Subscription.new(:user => @user, :plan => @monthly_plan)
      @company      = Factory(:company, :subscription => @subscription)
      assert_valid @subscription
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
        assert_equal Time.now.utc.beginning_of_day + 1.month, @subscription.next_billing_at.utc
      end
    
      should "should raise subscription error if billed again" do
        assert_raise SubscriptionError do
          @subscription.bill(@credit_card)
        end
      end
    end
  end
  
  context "free subscription" do
    setup do
      @free_plan    = Factory(:free_plan)
      @subscription = Subscription.new(:user => @user, :plan => @free_plan)
      @company      = Factory(:company, :subscription => @subscription)
      assert_valid @subscription
    end
  
    should_change "Subscription.count", :by => 1
  
    should "start with subscription in initialized state" do
      assert @subscription.initialized?
    end
  end
  
end