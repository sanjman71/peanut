require 'test/test_helper'
require 'test/factories'

class OpeningsControllerTest < ActionController::TestCase

  # search appointments for a specified schedulable and service
  should_route :post, 'users/1/services/3/openings/this-week/anytime', 
               :controller => 'openings', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 3, 
               :when => 'this-week', :time => 'anytime'

  # search appointments for a specified schedulable and service, with a specified service duration
  should_route :post, 'users/1/services/3/duration/45/openings/this-week/anytime',
               :controller => 'openings', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 3, 
               :duration => 45, :when => 'this-week', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration
  should_route :post, 'services/3/duration/120/openings/this-week/anytime', 
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120, :when => 'this-week', :time => 'anytime'
  
end
