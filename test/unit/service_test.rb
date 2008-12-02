require 'test/test_helper'

class ServiceTest < ActiveSupport::TestCase
  
  # shoulda
  should_require_attributes :company_id
  should_require_attributes :name
  should_require_attributes :duration
  should_require_attributes :price_in_cents
  should_allow_values_for   :mark_as, "free", "busy", "work"
  
  def test_should_titleize_name
    company = Factory(:company)
    object  = Service.create(:company => company, :name => "boring job", :duration => 30, :mark_as => "busy", :price => 1.00)
    assert object.valid?
    assert_equal "Boring Job", object.name
  end
  
  def test_should_create_polymorphic_resources
    company = Factory(:company)
    service = company.services.create(:company => company, :name => "boring job", :duration => 30, :mark_as => "busy", :price => 1.00)
    assert service.valid?
    
    # create skill
    person1 = Factory(:person, :name => "Sanjay", :companies => [company])
    service.resources.push(person1)
    service.reload
    assert_equal [person1], service.resources
    assert_equal [person1], service.people
  end
  
end
