namespace :bundle do

  desc "Install bundled gems"
  task :install, :roles => [:app, :db] do
    run "bash -ic 'cd #{current_path}; bundle install'"
  end
 
  # after deploy task
  desc "Update .bundle/config"
  task :config, :roles => [:app, :db] do
    puts "deploying .bundle/config"
    run "mkdir -p #{current_release}/.bundle"
    run "cp #{current_release}/config/templates/bundle.config.#{rails_env} #{current_release}/.bundle/config"
  end

end