require 'test/test_helper'

class ServiceTest < ActiveSupport::TestCase
  
  # shoulda
  should_require_attributes :company_id
  should_require_attributes :name
  should_require_attributes :duration
  should_allow_values_for   :mark_as, "free", "busy", "work"
  
  def test_should_titleize_name
    company = Factory(:company)
    o       = Service.create(:company => company, :name => "boring job", :duration => 30, :mark_as => "busy")
    assert o.valid?
    assert_equal "Boring Job", o.name
  end
end
