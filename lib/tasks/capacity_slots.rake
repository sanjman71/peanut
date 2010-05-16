namespace :calendar do
  
  namespace :capacity_slots do

    desc "rebuild capacity slots for all companies"
    task :rebuild_all do
        
      Company.with_appointments.each do |company|
        rebuild_capacity_slots_for_company(company)
      end

    end

    desc "rebuild capacity slots for a company. Specify company subdomain in SUBDOMAIN environment variable"
    task :rebuild_company do

      company = nil
      subdomain = ENV["SUBDOMAIN"]
      company = Company.find_by_subdomain(subdomain.downcase) unless subdomain.blank?
      
      if subdomain.blank?
        puts "You must specify the company subdomain in the SUBDOMAIN environment variable" and return 
      elsif company.blank?
        puts "You provided an invalid subdomain"
      else
        rebuild_capacity_slots_for_company(company)
      end

    end

    desc "show capacity of level CAPACITY or more for company SUBDOMAIN. Default CAPACITY is 2. SUBDOMAIN is required. Only future capacity is shown. If CAPACITY is negative, shows capacity of level CAPACITY or less"
    task :show_capacity do

      company = nil
      subdomain = ENV["SUBDOMAIN"]
      capacity = ENV["CAPACITY"].blank? ? 2 : ENV["CAPACITY"].to_i
      company = Company.find_by_subdomain(subdomain.downcase) unless subdomain.blank?
      
      if subdomain.blank?
        puts "You must specify the company subdomain in the SUBDOMAIN environment variable" and return 
      elsif company.blank?
        puts "You provided an invalid subdomain"
      else
        if capacity > 0
          capacity_slots = company.capacity_slots.future.capacity_gteq(capacity).order_start_at
          puts "Capacity slots for #{subdomain.to_s} with capacity >= #{capacity.to_s}"
        else
          capacity_slots = company.capacity_slots.future.capacity_lteq(capacity).order_start_at
          puts "Capacity slots for #{subdomain.to_s} with capacity <= #{capacity.to_s}"
        end
          
        capacity_slots.each do |slot|
          puts "#{slot.start_at.to_s(:appt_date_time_army)} capacity: #{slot.capacity.to_s} provider: #{slot.provider.name}"
        end
      end

    end
    
    desc "cancel duplicated availability, found using capacity of level CAPACITY or more for company SUBDOMAIN. Default CAPACITY is 2. SUBDOMAIN is required. Only future capacity is shown"
    task :cancel_dups do

      company = nil
      subdomain = ENV["SUBDOMAIN"]
      capacity = ENV["CAPACITY"] || 2
      company = Company.find_by_subdomain(subdomain.downcase) unless subdomain.blank?
      
      if subdomain.blank?
        puts "You must specify the company subdomain in the SUBDOMAIN environment variable" and return 
      elsif company.blank?
        puts "You provided an invalid subdomain"
      else
        capacity_slots = company.capacity_slots.future.capacity_gteq(capacity).order_start_at
        puts "Capacity slots for #{subdomain.to_s} with capacity >= #{capacity.to_s}"
        capacity_slots.each do |slot|
          puts "** capacity slot: #{slot.start_at.to_s(:appt_date_time_army)} capacity: #{slot.capacity.to_s} provider: #{slot.provider.name}"
          overlapping_frees = company.appointments.free.recurrence_instances.not_canceled.provider(slot.provider).overlap(slot.start_at, slot.end_at).order_id
          overlapping_frees_by_parent = overlapping_frees.group_by {|x| x.recur_parent }

          parents = overlapping_frees_by_parent.keys.compact
          parents.each do |parent|
            puts "**** parent: #{parent.id} start_at #{parent.start_at} end_at #{parent.end_at}"
            # Find out if we have an appointment we can keep, because it's the same as the parent
            one_to_keep = false
            overlapping_frees_by_parent[parent].each do |free|
              if ((free.start_at.hour  == parent.start_at.hour) && (free.start_at.min  == parent.start_at.min) && 
                  (free.end_at.hour == parent.end_at.hour) && (free.end_at.min == parent.end_at.min)) || (free.created_at != free.updated_at)
                one_to_keep = true
              end
            end

            if (one_to_keep)

              kept_one = false
              overlapping_frees_by_parent[parent].each do |free|
                if ((free.start_at.hour  == parent.start_at.hour) && (free.start_at.min  == parent.start_at.min) && 
                    (free.end_at.hour == parent.end_at.hour) && (free.end_at.min == parent.end_at.min))
                  if kept_one
                    # We've already kept one, so even though this is the same as the parent, we cancel it
                    puts "****** cancel same: #{free.id} start_at #{free.start_at} end_at #{free.end_at} parent #{free.recur_parent_id}"
                    AppointmentScheduler.cancel_appointment(free, true)
                  else
                    # We haven't kept one, and this is the same as the parent, so we keep it
                    puts "****** keep same:   #{free.id} start_at #{free.start_at} end_at #{free.end_at} parent #{free.recur_parent_id}"
                    kept_one = true
                  end
                elsif (free.created_at == free.updated_at)
                  # This is different from the parent and hasn't been updated since it was created. This implies the parent has changed since this was created
                  # We know there's another appointment the same as the parent (because one_to_keep is set) or there's another one that's different from the parent (like this)
                  # but has been updated since it was created. One of those will be kept, and so we'll cancel this.
                  puts "****** cancel diff: #{free.id} start_at #{free.start_at} end_at #{free.end_at} parent #{free.recur_parent_id}"
                  AppointmentScheduler.cancel_appointment(free, true)
                else
                  # This is different from the parent, but has been modified since it was created. We can't cancel this
                  puts "****** keep diff:   #{free.id} start_at #{free.start_at} end_at #{free.end_at} parent #{free.recur_parent_id}"
                  kept_one = true
                end
              end

            else
              puts "****** None to keep, not canceling any ********"
            end

          end

          puts "*****************************************************************"

        end

      end

    end
  end

  def rebuild_capacity_slots_for_company(company)

    puts "Processing company #{company.name}"

    # Fix all 0 capacity work appointments - these were forced previously
    # We do this in a transaction
    Appointment.transaction do

      company.appointments.work.each do |work_appointment|
        if work_appointment.capacity == 0
          work_appointment.capacity = work_appointment.service.capacity
          work_appointment.save
        end
      end
      
    end

    # Process the capacity slots for a company in a transaction
    CapacitySlot.transaction do

      # Remove all existing capacity slots for the company
      company.capacity_slots.destroy_all

      # Add capacity for each free appointment
      company.appointments.free.not_canceled.each do |appointment|
        CapacitySlot.change_capacity(company, appointment.location || Location.anywhere, appointment.provider, 
                                      appointment.start_at, appointment.end_at, appointment.capacity, :force => true)
      end

      # Remove capacity for each work appointment that hasn't been cancelled
      company.appointments.work.not_canceled.each do |appointment|
        CapacitySlot.change_capacity(company, appointment.location || Location.anywhere, appointment.provider, 
                                      appointment.start_at, appointment.end_at, -appointment.capacity, :force => true)
      end

    end

  end

end
