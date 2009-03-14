require 'test/test_helper'
require 'test/factories'

class OpeningsControllerTest < ActionController::TestCase

  # search appointments for a specified schedulable, duration and service, with a when range
  should_route :post, 'users/1/services/3/45/openings/this-week/anytime',
               :controller => 'openings', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 3, 
               :duration => 45, :when => 'this-week', :time => 'anytime'

  # search appointments for a specified schedulable, duration and service, with a date range
  should_route :post, 'users/1/services/3/45/openings/20090101..20090201/anytime',
               :controller => 'openings', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 3, 
               :duration => 45, :start_date => '20090101', :end_date => '20090201', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration, with a when range
  should_route :post, 'services/3/120/openings/this-week/anytime', 
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120, :when => 'this-week', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration, with a date range
  should_route :post, 'services/3/120/openings/20090101..20090201/anytime', 
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120, 
               :start_date => '20090101', :end_date => '20090201', :time => 'anytime'
  
end
