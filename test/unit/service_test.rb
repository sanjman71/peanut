require 'test/test_helper'

class ServiceTest < ActiveSupport::TestCase
  
  should_require_attributes :company_id
  should_require_attributes :name
  should_require_attributes :price_in_cents
  should_allow_values_for   :mark_as, "free", "busy", "work"
  
  should_belong_to          :company
  should_have_many          :appointments
  should_have_many          :skills
  should_have_many          :users, :through => :skills
  
  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    assert_valid @company
  end
  
  context "create service" do
    setup do
      @service = @company.services.create(:name => "boring job", :duration => 0, :mark_as => "busy", :price => 1.00)
      assert_valid @service
    end
    
    should "titleize name" do
      assert_equal "Boring Job", @service.name
    end
    
    should "have default duration of 30 minutes" do
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
      
      should "have user services count == 1" do
        assert_equal 1, @user1.services_count
      end
    end
  end
  
end
