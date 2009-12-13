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

if RAILS_ENV == 'production'

every 3.hours do
  # send appointment reminders for a specific subdomain
  command "curl http://peakpt.walnutcalendar.com/tasks/appointments/reminders/24-hours?token=#{AUTH_TOKEN_INSTANCE} > /dev/null"
end

every :reboot do
  # start sphinx searchd
  command "cd /usr/apps/peanut/current && RAILS_ENV=production /usr/bin/env rake ts:start"
  # start delayed job daemon
  command "cd /usr/apps/peanut/current; script/delayed_job -e production start"
end

end # production