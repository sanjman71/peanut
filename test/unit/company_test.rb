require 'test/test_helper'

class CompanyTest < ActiveSupport::TestCase

  # shoulda
  should_require_attributes :name
  should_require_attributes :time_zone
  # should_require_unique_attributes :name
  
  def test_should_set_subdomain_based_on_name
    c = Company.create(:name => "Mary's Hair Salon", :time_zone => "UTC")
    assert c.valid?
    assert_equal "maryshairsalon", c.subdomain
  
    c = Company.create(:name => "Jax-Salon", :time_zone => "UTC")
    assert c.valid?
    assert_equal "jaxsalon", c.subdomain
  end

  def test_should_titleize_name
    c = Company.create(:name => "jax salon", :time_zone => "Central Time (US & Canada)")
    assert c.valid?
    assert_equal "Jax Salon", c.name
  end

end
