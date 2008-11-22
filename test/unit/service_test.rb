require 'test/test_helper'

class ServiceTest < ActiveSupport::TestCase
  fixtures :companies
  
  # shoulda
  should_require_attributes :company_id
  should_require_attributes :name
  should_require_attributes :duration
  should_allow_values_for   :mark_as, "free", "busy"
  
  def test_should_titleize_name
    o = Service.create(:company_id => companies(:company1).id, :name => "boring job", :duration => 30, :mark_as => "busy")
    assert o.valid?
    assert_equal "Boring Job", o.name
  end
end
