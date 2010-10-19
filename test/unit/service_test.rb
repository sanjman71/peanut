require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  
  should validate_presence_of     :name
  should validate_presence_of     :company_id
  should validate_presence_of     :price_in_cents
  should_allow_values_for         :mark_as, "free", "work"
  should validate_presence_of     :capacity
  should validate_numericality_of :capacity
  
  should belong_to              :company
  should have_many              :appointments
  should have_many              :service_providers
  should_have_many              :user_providers, :through => :service_providers
  
  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    assert_valid @company
  end

  context "create service" do
    setup do
      @service = @company.services.create(:name => "boring job", :duration => 30 * 60, :mark_as => "work", :price => 1.00)
      assert_valid @service
    end

    should "titleize name" do
      assert_equal "Boring Job", @service.name
    end

    should "have duration of 30 minutes" do
      assert_equal 30 * 60, @service.duration
    end

    fast_context "create user and add as a service provider" do
      setup do
        @user1 = Factory(:user, :name => "Sanjay")
        assert_valid @user1
        @service.user_providers.push(@user1)
        @service.reload
        @user1.reload
      end

      should "change service.user_providers collection" do
        assert_equal [@user1], @service.user_providers
      end

      should "have service.provided_by? return true" do
        assert @service.provided_by?(@user1)
      end

      should "change service.providers_count" do
        assert_equal 1, @service.providers_count
      end

      should "cleanup after removing service provider" do
        @service.user_providers.delete(@user1)
        @service.reload
        # should change service.user_providers collection
        assert_equal [], @service.user_providers
        # should change service.providers_count
        assert_equal 0, @service.providers_count
      end
    end
  end
  
end
