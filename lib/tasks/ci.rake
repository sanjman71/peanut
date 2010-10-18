namespace :ci do
  
  desc "Run bundle install on a CI server"
  task :bundle do
    system("bundle install")
  end

  desc "Configure ci environment"
  task :configure do
    system("cp #{Rails.root}/config/templates/database.ci.yml #{Rails.root}/config/database.yml")
  end

  desc "Run the Continuous Integration build"
  task :run => ["ci:bundle", "ci:configure", "db:migrate"] do
    Rake::Task['test:units'].invoke
  end
  
end