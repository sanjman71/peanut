require 'test/test_helper'
require 'test/factories'

class AppointmentsControllerTest < ActionController::TestCase

  # show appointment schedule for a specific resource
  should_route :get, 'users/1/appointments',  :controller => 'appointments', :action => 'index', :resource => 'users', :id => 1
  should_route :get, 'resources/3/appointments',  :controller => 'appointments', :action => 'index', :resource => 'resources', :id => 3

  # search appointments for a specific resource
  should_route :post, 'resources/1/appointments/search', :controller => 'appointments', :action => 'search', :resource => 'resources', :id => 1
  
  # create/schedule a new apppointment for a specific resource
  # should_route :post, 'schedule/users/1/services/1/20090101',  
  #              :controller => 'appointments', :action => 'new', :resource => 'users', :id => 1, :service_id => 1, :start_at => "20090101"
                                                               
  # create/schedule a waitlist appointment for a specific resource
  should_route :post, 'waitlist/users/1/services/5/this-week/morning', 
               :controller => 'appointments', :action => 'new', :resource => 'users', :id => 1, :service_id => 5, :when => 'this-week', :time => 'morning'

  # create/schedule a new apppointment for a specific resource
  should_route :get, 'schedule/users/3/services/3/20090303T113000',
                :controller => 'appointments', :action => 'new', :resource => 'users', :id => 3, :service_id => 3, :start_at => '20090303T113000'
  should_route :post, 'schedule/users/3/services/3/20090303T113000',
                :controller => 'appointments', :action => 'create', :resource => 'users', :id => 3, :service_id => 3, :start_at => '20090303T113000'
                
end
