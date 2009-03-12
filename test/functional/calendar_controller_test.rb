require 'test/test_helper'
require 'test/factories'

class CalendarControllerTest < ActionController::TestCase

  # show calendar for a specific schedulable
  should_route :get, 'users/1/calendar',  :controller => 'calendar', :action => 'show', :schedulable_type => 'users', :schedulable_id => 1
  
  # search calendar for a specific schedulable
  should_route :post, 'users/1/calendar/search', 
               :controller => 'calendar', :action => 'search', :schedulable_type => 'users', :schedulable_id => 1

  # edit calendar for a specific schedulable
  should_route :get, 'users/1/calendar/edit', 
               :controller => "calendar", :action => 'edit', :schedulable_type => "users", :schedulable_id => "1"
  
end
