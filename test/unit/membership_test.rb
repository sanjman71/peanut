require 'test/test_helper'
require 'test/factories'

class MembershipTest < ActiveSupport::TestCase
  
  # shoulda
  should_require_attributes :service_id
  should_require_attributes :resource_id
  should_require_attributes :resource_type
  
  def test_membership
    company   = Factory(:company)
    person    = Factory(:person, :name => "Sanjay", :companies => [company])
    haircut   = Factory(:work_service, :name => "Haircut", :company => company, :price => 1.00)
    
    # should create membership
    assert_difference('Membership.count') do
      membership = Membership.create(:resource => person, :service => haircut)
      assert membership.valid?
    end
  
    # should not create membership with invalid resource
    assert_no_difference('Membership.count') do
      membership = Membership.create(:resource_id => -1, :resource_type => "Person", :service => haircut)
      assert !membership.valid?
    end

    # should not create membership with invalid service
    assert_no_difference('Membership.count') do
      membership = Membership.create(:resource => person, :service_id => 0)
      assert !membership.valid?
    end
  end
  
end