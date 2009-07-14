require 'test/test_helper'

class ServiceTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :name
  should_validate_presence_of   :price_in_cents
  should_allow_values_for       :mark_as, "free", "work"
  
  should_have_many              :companies, :through => :company_services
  should_have_many              :appointments
  should_have_many              :service_providers
  should_have_many              :users, :through => :service_providers
  
  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    assert_valid @company
  end
  
  context "create service" do
    setup do
      @service = @company.services.create(:name => "boring job", :duration => 30, :mark_as => "work", :price => 1.00)
      assert_valid @service
    end
    
    should "titleize name" do
      assert_equal "Boring Job", @service.name
    end
    
    should "have duration of 30 minutes" do
      assert_equal 30, @service.duration
    end
    
    context "create user and assign it as a service provider" do
      setup do
        @user1 = Factory(:user, :name => "Sanjay")
        assert_valid @user1
        @service.providers.push(@user1)
        @service.reload
        @user1.reload
      end
      
      should "have service providers collection == [@user]" do
        assert_equal [@user1], @service.providers
        assert_equal [@user1], @service.users
      end
      
      should "have service provided_by? return true" do
        assert @service.provided_by?(@user1)
      end
    end
  end
  
end
