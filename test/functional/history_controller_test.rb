require 'test/test_helper'

class HistoryControllerTest < ActionController::TestCase

  should_route :get, '/history', :controller => 'history', :action => 'index'
  should_route :get, '/history/waitlist', :controller => 'history', :action => 'waitlist'

end