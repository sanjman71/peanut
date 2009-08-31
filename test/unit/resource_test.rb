require 'test/test_helper'

class ResourceTest < ActiveSupport::TestCase

  should_validate_presence_of :name
  
  def setup
    # create a valid company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    assert_valid @company
  end
  
  context "create resource" do
    setup do
      @resource = Resource.create(:name => "Mac Truck")
      assert @resource.valid?
    end

    context "and add as a company provider" do
      setup do
        @company.resource_providers.push(@resource)
        @company.reload
      end

      should "change company.resource_providers" do
        assert_equal [@resource], @company.resource_providers
      end

      should "increment company.providers_count" do
        assert_equal 1, @company.providers_count
      end

      context "then remove resource provider" do
        setup do
          @company.resource_providers.delete(@resource)
          @company.reload
        end

        should "change company.resource_providers" do
          assert_equal [], @company.resource_providers
        end

        should "decrement company.providers_count" do
          assert_equal 0, @company.providers_count
        end
      end
    end
  end
  
end
