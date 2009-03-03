require 'test/test_helper'
require 'test/factories'

class SkillTest < ActiveSupport::TestCase
  
  should_require_attributes :service_id
  should_require_attributes :provider_id
  should_require_attributes :provider_type

  def setup
    @user         = Factory(:user, :name => "Sanjay")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @user, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @haircut      = Factory(:work_service, :name => "Haircut", :company => @company, :price => 1.00)
  end
  
  context "create valid skill" do
    setup do
      @skill = Skill.create(:provider => @user, :service => @haircut)
      assert_valid @skill
    end
    
    should_change "Skill.count", :by => 1
  end
  
  context "skill with invalid provider" do
    setup do
      @skill = Skill.create(:provider_id => -1, :provider_type => "User", :service => @haircut)
    end
    
    should_not_change "Skill.count"
  end

  context "skil with invalid service" do
    setup do
      @skill = Skill.create(:provider => @user, :service_id => 0)
    end

    should_not_change "Skill.count"
  end
    
end