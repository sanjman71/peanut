require 'test/test_helper'
require 'test/factories'

class FreeControllerTest < ActionController::TestCase

  # add free time for a specific resource
  should_route :get, 'users/1/free/block', :controller => "free", :action => 'new', :resource => "users", :id => "1", :style => "block"
  
end
