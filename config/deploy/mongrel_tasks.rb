namespace :mongrel do
  
  desc "Stop all mongrels"
  task :stop, :roles => :app do
    sudo "god stop mongrel"
  end

  desc "Start all mongrels"
  task :start, :roles => :app do
    sudo "god start mongrel"
  end

  desc "Restart all mongrels"
  task :restart, :roles => :app do
    sudo "god restart mongrel"
  end
  
end