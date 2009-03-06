require 'test/test_helper'
require 'test/factories'

class ServiceProviderTest < ActiveSupport::TestCase
  
  should_require_attributes :service_id
  should_require_attributes :schedulable_id
  should_require_attributes :schedulable_type

  def setup
    @user         = Factory(:user, :name => "Sanjay")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @user, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @haircut      = Factory(:work_service, :name => "Haircut", :companies => [@company], :price => 1.00)
  end
  
  context "create valid service provider" do
    setup do
      @skill = ServiceProvider.create(:schedulable => @user, :service => @haircut)
      assert_valid @skill
    end
    
    should_change "ServiceProvider.count", :by => 1
  end
  
  context "skill with invalid provider" do
    setup do
      @skill = ServiceProvider.create(:schedulable_id => -1, :schedulable_type => "User", :service => @haircut)
    end
    
    should_not_change "ServiceProvider.count"
  end

  context "skil with invalid service" do
    setup do
      @skill = ServiceProvider.create(:schedulable => @user, :service_id => 0)
    end

    should_not_change "ServiceProvider.count"
  end
    
end