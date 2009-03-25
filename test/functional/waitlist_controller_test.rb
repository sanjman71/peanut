require 'test/test_helper'
require 'test/factories'

class WaitlistControllerTest < ActionController::TestCase

  # show waitlist for a specific schedulable
  should_route :get, 'users/1/waitlist',  :controller => 'waitlist', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1
  
end