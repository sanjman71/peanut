require 'test/test_helper'

class JobTest < ActiveSupport::TestCase
  # shoulda
  should_require_attributes :name
  should_require_attributes :duration
  should_allow_values_for :mark_as, "free", "busy"
  
  def test_should_titleize_name
    job = Job.create(:name => "boring job", :duration => 30, :mark_as => "busy")
    assert job.valid?
    assert_equal "Boring Job", job.name
  end
end
