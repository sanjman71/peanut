require 'test/test_helper'
require 'test/factories'

class PersonTest < ActiveSupport::TestCase

  def test_create
    company = Factory(:company)
    person1 = Factory(:person, :name => "Sanjay", :companies => [company])
    assert person1.valid?
    company.reload
    assert_equal [person1], company.people

    person2 = Factory(:person, :name => "Killian", :companies => [company])
    assert person2.valid?
    company.reload
    assert_equal [person1, person2], company.people
  end
  
end
