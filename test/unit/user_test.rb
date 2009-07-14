require 'test/test_helper'
require 'test/factories'

class UserTest < ActiveSupport::TestCase

  should_belong_to    :mobile_carrier
  should_have_many    :subscriptions
  should_have_many    :plans, :through => :subscriptions
  should_have_many    :appointments

end
