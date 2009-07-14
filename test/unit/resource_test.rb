require 'test/test_helper'
require 'test/factories'

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
        @company.providers.push(@resource)
        @company.reload
      end

      should "should have company providers == [@resource]" do
        assert_equal [@resource], @company.providers
      end
    end
  end
  
end
