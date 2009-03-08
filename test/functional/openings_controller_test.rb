require 'test/test_helper'
require 'test/factories'

class OpeningsControllerTest < ActionController::TestCase

  # search appointments for a specific schedulable
  should_route :post, 'users/1/services/3/openings/this-week/anytime', 
               :controller => 'openings', :action => 'index', :schedulable_type => 'users', :schedulable_id => 1, :service_id => 3, 
               :when => 'this-week', :time => 'anytime'
  
end
