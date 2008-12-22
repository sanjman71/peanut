if RAILS_ENV == 'development'
  RAILS_ROOT = File.dirname(File.dirname(__FILE__))
els
  RAILS_ROOT = "/usr/apps/peanut/current"
end

def generic_monitoring(w, options = {})
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 10.seconds
      c.running = false
    end
  end
  
  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = options[:memory_limit]
      c.times = [3, 5] # 3 out of 5 intervals
    end
  
    restart.condition(:cpu_usage) do |c|
      c.above = options[:cpu_limit]
      c.times = 5
    end
  end
  
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state      = [:start, :restart]
      c.times         = 5
      c.within        = 5.minute
      c.transition    = :unmonitored
      c.retry_in      = 10.minutes
      c.retry_times   = 5
      c.retry_within  = 2.hours
    end
  end
end

God.watch do |w|
  script            = "#{RAILS_ROOT}/script/workling_client"
  w.name            = "peanut-workling"
  w.group           = "peanut"
  w.interval        = 60.seconds
  w.start           = "#{script} start"
  w.restart         = "#{script} restart"
  w.stop            = "#{script} stop"
  w.start_grace     = 20.seconds
  w.restart_grace   = 20.seconds
  w.pid_file        = "#{RAILS_ROOT}/log/workling.pid"
  
  w.behavior(:clean_pid_file)
  
  generic_monitoring(w, :cpu_limit => 80.percent, :memory_limit => 100.megabytes)
end

God.watch do |w|
  w.name            = "peanut-starling"
  w.group           = "peanut"
  w.interval        = 60.seconds
  w.start           = "starling -d -P #{RAILS_ROOT}/log/starling.pid -q #{RAILS_ROOT}/log/"
  w.stop            = "kill `cat #{RAILS_ROOT}/log/starling.pid`"
  w.start_grace     = 10.seconds
  w.restart_grace   = 10.seconds
  w.pid_file        = "#{RAILS_ROOT}/log/starling.pid"
  
  w.behavior(:clean_pid_file)
  
  generic_monitoring(w, :cpu_limit => 30.percent, :memory_limit => 20.megabytes)
end

# run these in staging, production environments
unless ENV['RAILS_ENV'] == 'development'
  
  %w{5000 5001}.each do |port|
    God.watch do |w|
      w.name          = "peanut-mongrel-#{port}"
      w.group         = "mongrel"
      w.interval      = 60.seconds      
      w.start         = "mongrel_rails start -c #{RAILS_ROOT} -p #{port} \
                        -P #{RAILS_ROOT}/log/mongrel.#{port}.pid  -d"
      w.stop          = "mongrel_rails stop -P #{RAILS_ROOT}/log/mongrel.#{port}.pid"
      w.restart       = "mongrel_rails restart -P #{RAILS_ROOT}/log/mongrel.#{port}.pid"
      w.start_grace   = 10.seconds
      w.restart_grace = 10.seconds
      w.pid_file      = "#{RAILS_ROOT}/log/mongrel.#{port}.pid"
    
      w.behavior(:clean_pid_file)

      generic_monitoring(w, :cpu_limit => 50.percent, :memory_limit => 150.megabytes)
    end
  end

  God.watch do |w|
    w.name            = "peanut-nginx"
    w.group           = "nginx"
    w.interval        = 30.seconds # default
    w.start           = "/etc/init.d/nginx start"
    w.stop            = "/etc/init.d/nginx stop"
    w.restart         = "/etc/init.d/nginx restart"
    w.start_grace     = 20.seconds
    w.restart_grace   = 20.seconds
    w.pid_file        = "/usr/local/nginx/logs/nginx.pid"

    w.behavior(:clean_pid_file)

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
      # failsafe
      on.condition(:tries) do |c|
        c.times = 8
        c.within = 2.minutes
        c.transition = :start
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_exits)
    end

    # w.transition(:up, :restart) do |on|
    #   on.condition(:http_response_code) do |c|
    #     c.host = 'localhost'
    #     c.port = 5000
    #     c.path = '/monitor.html'
    #     c.code_is_not = 200
    #     c.timeout = 10.seconds
    #     c.times = [3, 5]
    #   end
    # end

    generic_monitoring(w, :cpu_limit => 50.percent, :memory_limit => 75.megabytes)
  end

end # unless 'development'