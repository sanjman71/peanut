require 'test/test_helper'

class CompanyTest < ActiveSupport::TestCase

  # shoulda
  should_require_attributes :name
  # should_require_unique_attributes :name
  
  def test_should_set_subdomain_based_on_name
    c = Company.create(:name => "Mary's Hair Salon")
    assert c.valid?
    assert_equal "maryshairsalon", c.subdomain
  
    c = Company.create(:name => "Salon Sixty-Five")
    assert c.valid?
    assert_equal "salonsixtyfive", c.subdomain
  end
  
end
