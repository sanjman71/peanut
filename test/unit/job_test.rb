require 'test/test_helper'

class JobTest < ActiveSupport::TestCase
  # shoulda
  should_require_attributes :name
  should_require_attributes :duration

  
  def test_should_titleize_name
    job = Job.create(:name => "boring job", :duration => 30)
    assert job.valid?
    assert_equal "Boring Job", job.name
  end
end
