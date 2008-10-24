require 'test/test_helper'

class CustomerTest < ActiveSupport::TestCase
  # shoulda
  should_require_attributes :name
  should_require_attributes :email
  should_require_attributes :phone
  
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
