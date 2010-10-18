# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :cron_log, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# update, write crontab:
# whenever --update-crontab walnut_calendar
# whenever --write-crontab walnut_calendar

set :environment, :production
set :path, '/usr/apps/peanut/current'
# set :output, {:standard => '/usr/apps/peanut/current/log/cron.log', :error => '/usr/apps/peanut/current/log/cron.log'} 

every :reboot do
  # start sphinx searchd
  command "cd /usr/apps/peanut/current && RAILS_ENV=production /usr/bin/env rake ts:start"
  # start delayed job daemon
  command "cd /usr/apps/peanut/current; script/delayed_job -e production start"
end

every 5.minutes do
  command "curl http://www.walnutcalendar.com/ping > /dev/null"
end

# every 3.hours do
#   # check/send appointment reminders for all companies with subscriptions
#   Subscription.all.collect(&:company).each do |company|
#     # send appointment reminders for a specific subdomain
#     command "curl http://#{company.subdomain}.walnutcalendar.com/tasks/appointments/reminders/24-hours?token=#{AUTH_TOKEN_INSTANCE} > /dev/null"
#   end
# end

# every 1.day, :at => '1:00 am' do
every 5.minutes do
  # expand recurrences for all companies with subscriptions
  # rake "appointments:recurrence:expand COMPANY='meatheads'"
  command "curl http://meatheads.walnutcalendar.com/tasks/expand_all_recurrences?token=5e722026ea70e6e497815ef52f9e73c5ddb8ac26 > /dev/null"

  # Subscription.all.collect(&:company).each do |company|
  #   # expand recurrences for a specific subdomain
  #   command "rake rake appointments:recurrence:expand COMPANY='#{company.name}'"
  #   # command "curl http://#{company.subdomain}.walnutcalendar.com/tasks/expand_all_recurrences?token=#{AUTH_TOKEN_INSTANCE} > /dev/null"
  # end
end

every 1.day, :at => '1:00 am' do
  command "rake init:rebuild_demos"
end

every 1.day, :at => '6:00 am' do
  # send daily schedules for all companies with subscriptions
  # Subscription.all.collect(&:company).each do |company|
  #   command "curl http://#{company.subdomain}.walnutcalendar.com/tasks/schedules/messages/daily?token=#{AUTH_TOKEN_INSTANCE} > /dev/null"
  # end
end
