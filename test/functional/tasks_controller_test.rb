require 'test/test_helper'

class TasksControllerTest < ActionController::TestCase

  should_route :get, '/tasks/appointments/reminders/2-days', :controller => 'tasks', :action => 'appointments_reminders', :time_span => '2-days'
  should_route :get, '/tasks/appointments/messages/whenever', :controller => 'tasks', :action => 'appointments_messages', :time_span => 'whenever'

end