require 'test/test_helper'
require 'test/factories'

class MembershipTest < ActiveSupport::TestCase
  
  should_require_attributes :service_id
  should_require_attributes :resource_id
  should_require_attributes :resource_type

  def setup
    @company   = Factory(:company)
    @user      = Factory(:user, :name => "Sanjay", :companies => [@company])
    @haircut   = Factory(:work_service, :name => "Haircut", :company => @company, :price => 1.00)
  end
  
  context "valid membership" do
    setup do
      @membership = Membership.create(:resource => @user, :service => @haircut)
      assert_valid @membership
    end
    
    should_change "Membership.count", :by => 1
  end
  
  context "membership with invalid resource" do
    setup do
      @membership = Membership.create(:resource_id => -1, :resource_type => "User", :service => @haircut)
    end
    
    should_not_change "Membership.count"
  end

  context "membership with invalid service" do
    setup do
      @membership = Membership.create(:resource => @user, :service_id => 0)
    end

    should_not_change "Membership.count"
  end
    
end