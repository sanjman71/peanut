require 'test/test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  
  # index route
  should_route :get, '/subscriptions',  :controller => 'subscriptions', :action => 'index'
  should_route :get, '/subscriptions/errors', :controller => 'subscriptions', :action => 'index', :filter => 'errors'
  
end
