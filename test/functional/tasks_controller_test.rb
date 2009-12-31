require 'test/test_helper'

class TasksControllerTest < ActionController::TestCase

  should_route :get, '/tasks/appointments/reminders/2-days', :controller => 'tasks', :action => 'appointment_reminders', :time_span => '2-days'
  should_route :get, '/tasks/appointments/messages/whenever', :controller => 'tasks', :action => 'appointment_messages', :time_span => 'whenever'
  should_route :get, '/tasks/users/messages/whenever', :controller => 'tasks', :action => 'user_messages', :time_span => 'whenever'
  should_route :get, '/tasks/expand_all_recurrences', :controller => 'tasks', :action => 'expand_all_recurrences'

end