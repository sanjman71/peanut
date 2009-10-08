require 'test/test_helper'

class WaitlistTimeRangeTest < ActiveSupport::TestCase
  should_belong_to              :waitlist

  should_validate_presence_of   :waitlist_id
  should_validate_presence_of   :start_date
  should_validate_presence_of   :end_date
  should_validate_presence_of   :start_time
  should_validate_presence_of   :end_time

end