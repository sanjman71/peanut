require 'test/test_helper'
require 'test/factories'

class FreeControllerTest < ActionController::TestCase

  # add free time for a specific schedulable
  should_route :get, 'users/1/free/block', :controller => "free", :action => 'new', :schedulable_type => "users", :schedulable_id => "1", :style => "block"
  
end
