require 'test/test_helper'
require 'test/factories'

class InvitationsControllerTest < ActionController::TestCase

  should_route :get,  '/invitations/new', :controller => 'invitations', :action => 'new'

end