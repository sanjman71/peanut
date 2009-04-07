require 'test/test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  
  # index route
  should_route :get, '/subscriptions',  :controller => 'subscriptions', :action => 'index'
  
  # update subscription route
  should_route :get, '/subscriptions/1/plan/3', :controller => 'subscriptions', :action => 'update', :id => 1, :plan_id => 3
end
