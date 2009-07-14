require 'test/test_helper'
require 'test/factories'

class ServiceProviderTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :service_id
  should_validate_presence_of   :provider_id
  should_validate_presence_of   :provider_type

  def setup
    @user         = Factory(:user, :name => "Sanjay")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @user, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @haircut      = Factory(:work_service, :name => "Haircut", :companies => [@company], :price => 1.00)
  end
  
  context "create valid service provider" do
    setup do
      @service_provider = ServiceProvider.create(:provider => @user, :service => @haircut)
      assert_valid @service_provider
    end
    
    should_change "ServiceProvider.count", :by => 1
  end
  
  context "service_provider with invalid provider" do
    setup do
      @service_provider = ServiceProvider.create(:provider_id => -1, :provider_type => "User", :service => @haircut)
    end
    
    should_not_change "ServiceProvider.count"
  end

  context "skil with invalid service" do
    setup do
      @service_provider = ServiceProvider.create(:provider => @user, :service_id => 0)
    end

    should_not_change "ServiceProvider.count"
  end
    
end