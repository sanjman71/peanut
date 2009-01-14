require 'test/test_helper'

class ServiceTest < ActiveSupport::TestCase
  
  should_require_attributes :company_id
  should_require_attributes :name
  should_require_attributes :duration
  should_require_attributes :price_in_cents
  should_allow_values_for   :mark_as, "free", "busy", "work"
  
  context "create service" do
    setup do
      @company = Factory(:company)
      @service = @company.services.create(:company => @company, :name => "boring job", :duration => 30, :mark_as => "busy", :price => 1.00)
      assert_valid @service
    end
    
    should "titleize name" do
      assert_equal "Boring Job", @service.name
    end
    
    context "create person with skillset" do
      setup do
        @person1 = Factory(:person, :name => "Sanjay", :companies => [@company])
        assert_valid @person1
        @service.resources.push(@person1)
        @service.reload
      end
      
      should "have service provided by person" do
        assert_equal [@person1], @service.resources
        assert_equal [@person1], @service.people
      end
    end
  end
  
end
