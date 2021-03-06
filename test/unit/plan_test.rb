require 'test_helper'

class PlanTest < ActiveSupport::TestCase
  should_validate_presence_of   :name, :cost
  should_have_many              :companies
  should_have_many              :users
  should_have_many              :subscriptions
  
  context "create monthly plan" do
    setup do
      @monthly_plan = Plan.create(:name => "monthly", :cost => 1000, 
                                  :start_billing_in_time_amount => 1, :start_billing_in_time_unit => "months",
                                  :between_billing_time_amount => 1, :between_billing_time_unit => "months")
    end
    
    should_change("Plan.count", :by => 1) { Plan.count }

    should "be billable" do
      assert @monthly_plan.billable?
    end
    
    should "have start billing at in 1 month" do
      assert_equal Time.now.utc.beginning_of_day + 1.month, @monthly_plan.start_billing_at
    end
    
    should "have 1 billing cycle of 1 month" do
      assert_equal 1.month, @monthly_plan.billing_cycle
    end

    should "have 2 billing cycles of 2 months" do
      assert_equal 2.months, @monthly_plan.billing_cycle(2)
    end
  end

  context "create free plan" do
    setup do
      @free_plan =  Plan.create(:name => "free", :cost => 0)
    end

    should_change("Plan.count", :by => 1) { Plan.count }

    should "not be billable" do
      assert !@free_plan.billable?
    end
    
    should "have no start billing at" do
      assert_equal nil, @free_plan.start_billing_at
    end

    should "have billing cycle of 0" do
      assert_equal 0, @free_plan.billing_cycle
    end
  end
end
