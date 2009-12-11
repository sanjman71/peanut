require 'test/test_helper'

class TasksControllerTest < ActionController::TestCase

  should_route :get, '/tasks/appointments/reminders/2-days', :controller => 'tasks', :action => 'appointments_reminders', :time_span => '2-days'

end