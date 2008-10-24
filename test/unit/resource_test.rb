require 'test/test_helper'

class ResourceTest < ActiveSupport::TestCase

  # shoulda
  should_require_attributes :name
  should_require_attributes :company_id

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
