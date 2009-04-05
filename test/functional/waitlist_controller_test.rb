require 'test/test_helper'
require 'test/factories'

class WaitlistControllerTest < ActionController::TestCase

  # show waitlist for a specific schedulable by state
  should_route :get, '/users/1/waitlist/upcoming',  
               :controller => 'waitlist', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1, :state => 'upcoming'
  # show waitlist for a specific schedulable, no state
  should_route :get, '/users/1/waitlist',  
               :controller => 'waitlist', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1
  # show waitlist for anyone
  should_route :get, '/waitlist', :controller => 'waitlist', :action => 'index'

end