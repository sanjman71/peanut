require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

# include named routes
include ActionController::UrlWriter

namespace :mechanize do
  
  case RAILS_ENV
  when 'development'
    @@host = 'http://www.walnutcalendar.dev:3001'
  when 'production'
    @@host = 'http://www.walnutcalendar.com'
  end

  desc "Test company openings for correctness by comparing the user interface against the database"
  task :openings do
    @company  = ENV["COMPANY"] ? Company.find_by_subdomain(ENV["COMPANY"]) : Company.first
    @location = Location.anywhere
    @provider = User.anyone
    @service  = @company.services.work.first
    @when     = 'next-week'
    @url      = openings_anyone_when_url(:service_id => @service.id, :duration => @service.duration, :when => @when, :time => 'anytime',
                                         :host => @@host, :subdomain => @company.subdomain)

    puts "*** url: #{@url.inspect}"

    # todo - add check for public/private company
  
    @agent = WWW::Mechanize.new
    @agent.get(@url)
    @agent.page.at("div#free_capacity_slots").css("div.slots").each do |div_slot|
      div_slot_id   = div_slot.attribute("id")
      slot_date     = div_slot_id.to_s.match(/slots_(\d+)/)[1] # e.g. slots_20100201

      puts "*** date: #{slot_date}"

      # find database capacity slots for the specified day
      daterange                 = DateRange.parse_range(slot_date, slot_date)
      db_cap_slots              = AppointmentScheduler.find_free_capacity_slots(@company, @location, @provider, @service, @service.duration, daterange)
      db_cap_slots_by_provider  = db_cap_slots.group_by { |cap_slot| cap_slot.provider }

      db_cap_slots_by_provider.each do |provider, db_cap_slots|
        puts "*** provider: #{provider.name}"
        # puts provider.inspect, cap_slots.inspect
        
        # find provider div, available times
        div_slot_id_provider  = div_slot.css("##{div_slot_id.to_s}_provider_#{provider.id}")
        select_slot_times     = div_slot_id_provider.css("select#slot_times option")
        
        # check that each time slot is covered by an available capacity slot
        select_slot_times.each do |select_slot_time|
          # puts select_slot_time.inspect
          time_string     = select_slot_time.attribute("value").to_s # e.g. 20100131T100000
          next if !time_string.match(/\dT+/) # skip 'Select a Time' option
          # parse time in company time zone
          select_start_at = ActiveSupport::TimeZone.new(@company.time_zone).parse(time_string)
          select_end_at   = select_start_at + @service.duration.seconds
          # chck that the slot time range is covered with a database capacity slot
          covered = db_cap_slots.any?{ |db_cap_slot| db_cap_slot.covers_range_incl?(select_start_at, select_end_at) }
          if !covered
            puts "[error] start: #{select_start_at}, end: #{select_end_at}"
          end
        end
      end
    end
  end # task

  desc "Test company schedules for correctness by comparing the user interface against the database"
  task :schedules do
    @company    = ENV["COMPANY"] ? Company.find_by_subdomain(ENV["COMPANY"]) : Company.first
    @location   = Location.anywhere
    @providers  = @company.providers

    @agent      = WWW::Mechanize.new
    
    @providers.slice(0,1).each do |provider|
      # build url with auth token since viewing calendars requires authentication
      url = calendar_show_url(:provider_type => provider.tableize, :provider_id => provider.id, :host => @@host, :subdomain => @company.subdomain)
      url += "/range/20100125..20100125"
      url += "?token=#{AUTH_TOKEN_INSTANCE}"
      puts "*** url: #{url.inspect}"
      @agent.get(url)

      puts "*** provider: #{provider.name}"

      # iterate through each schedule date
      @agent.page.at("div#calendar_by_day").css("div.calendar_schedule_date").slice(0,2).each do |div_schedule_date|
        schedule_date = div_schedule_date.to_s.match(/date_(\d+)/)[1] # e.g. date_20100201

        puts "*** date: #{schedule_date}"

        # find database capacity slots for the specified day, which could be in the past 
        daterange     = DateRange.parse_range(schedule_date, schedule_date)
        keep_old      = true
        db_cap_slots  = AppointmentScheduler.find_free_capacity_slots(@company, @location, provider, nil, nil, daterange, :keep_old => keep_old)
        db_free_appts = AppointmentScheduler.find_free_appointments(@company, @location, provider, nil, nil, daterange, :keep_old => keep_old)
        db_work_appts = AppointmentScheduler.find_work_appointments(@company, @location, provider, daterange)
        # puts db_cap_slots.inspect

        # parse schedule date for capacity slots, free appts, work appts

        div_schedule_date.css("div.free.capacity_slot").each_with_index do |div_cap_slot, i|
          puts "*** checking capacity slots" if i == 0
          # puts div_cap_slot.inspect
          time_range  = div_cap_slot.css("div.time span").text(); # e.g. 09:00 AM - 12:00 PM
          time_start  = ActiveSupport::TimeZone.new(@company.time_zone).parse("#{schedule_date} #{time_range.split('-')[0].strip}")
          time_end    = ActiveSupport::TimeZone.new(@company.time_zone).parse("#{schedule_date} #{time_range.split('-')[1].strip}")
          # puts time_range, time_start, time_end

          # check that the time range is covered with a database capacity slot
          covered = db_cap_slots.any?{ |db_cap_slot| db_cap_slot.covers_range_incl?(time_start, time_end) }
          if !covered
            puts "[error] start: #{time_start}, end: #{time_end}"
          end
        end

        div_schedule_date.css("div.free.appointment").each_with_index do |div_free_appt, i|
          puts "*** checking free appointments" if i == 0
          # puts div_free_appt.inspect
          time_range  = div_free_appt.css("div.time span").text(); # e.g. 09:00 AM - 12:00 PM
          time_start  = ActiveSupport::TimeZone.new(@company.time_zone).parse("#{schedule_date} #{time_range.split('-')[0].strip}")
          time_end    = ActiveSupport::TimeZone.new(@company.time_zone).parse("#{schedule_date} #{time_range.split('-')[1].strip}")
          # puts time_range, time_start, time_end

          # check that the time range is covered with a database free appointment
          covered = db_free_appts.any?{ |db_appt| (db_appt.start_at <= time_start) && (db_appt.end_at >= time_end) }
          if !covered
            puts "[error] start: #{time_start}, end: #{time_end}"
          end
        end

        div_schedule_date.css("div.work.appointment").each_with_index do |div_work_appt, i|
          puts "*** checking work appointments" if i == 0
          # puts div_work_appt.inspect
          time_range  = div_work_appt.css("div.time span").text(); # e.g. 09:00 AM - 12:00 PM
          time_start  = ActiveSupport::TimeZone.new(@company.time_zone).parse("#{schedule_date} #{time_range.split('-')[0].strip}")
          time_end    = ActiveSupport::TimeZone.new(@company.time_zone).parse("#{schedule_date} #{time_range.split('-')[1].strip}")

          # check that the time range is covered with a database work appointment
          covered = db_work_appts.any?{ |db_appt| (db_appt.start_at <= time_start) && (db_appt.end_at >= time_end) }
          if !covered
            puts "[error] start: #{time_start}, end: #{time_end}"
          end
        end

      end
    end
  end # task
  
end # mechanize
