namespace :schedules do
  
  desc "Break weekly schedules into schedules for a single day"
  task :break_weekly_schedules_into_single_days do
    Company.with_subscriptions.each do |company|
      company.authorized_providers.each do |provider|
        # find all provider weekly schedules
        weekly_recurrences = provider.provided_appointments.free.recurring.not_canceled
        # filter out schedules that occur on a single day
        weekly_recurrences = weekly_recurrences.delete_if { |o| Recurrence.days(o.recur_rule).size == 1 }
        # skip empty collections
        next if weekly_recurrences.empty?

        # puts "*** weekly recurrences: #{provider.name}: #{weekly_recurrences.inspect}"
        puts "*** weekly recurrence for: #{provider.name}"
        
        weekly_recurrences.each do |recurrence|
          puts "*** days: #{Recurrence.days(recurrence.recur_rule, :format => :long).join(',')}"

          errors = 0
          Recurrence.days(recurrence.recur_rule, :format => :short).each do |day|
            # build new recur rule, copy other fields from original recurrence
            rule    = "FREQ=FREQ=WEEKLY;BYDAY=%s" % day.slice(0,2).upcase
            options = Hash[:start_at => recurrence.start_at, :end_at => recurrence.end_at, :capacity => 1, :recur_rule => rule]
            puts "*** new options: #{options.inspect}"
            begin
              # create new recurrence
              appt = AppointmentScheduler.create_free_appointment(recurrence.company, recurrence.location, provider, options)
            rescue Exception => e
              puts "[error] #{e.message}"
              errors += 1
            end
          end

          if errors > 0
            puts "[error] not canceling original recurring because of errors"
            next
          end

          puts "*** canceling original recurrence"

          begin
            # First cancel the recurrence parent, so it doesn't continue to expand
            rp = recurrence.recurrence_parent
            
            # It may have already been canceled, and the user simply wants to cancel additional instances
            AppointmentScheduler.cancel_appointment(rp, true) unless rp.canceled?

            # We cancel all appointments after the selected appointment, of after the current time, whichever is later
            cancel_time = Time.zone.now

            # Now cancel all expanded instances after this appointment, including this one.
            # This does not include the recurrence parent itself.
            rp.recur_instances.after_incl(cancel_time).each do |recur_instance|
                AppointmentScheduler.cancel_appointment(recur_instance, true) unless recur_instance.canceled?
            end
          rescue OutOfCapacity => e
             puts "[error] #{e.message}"
          end
        end
      end
    end
  end
  
end 