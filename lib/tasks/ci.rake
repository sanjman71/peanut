namespace :ci do
  
  desc "Run bundle install on a CI server"
  task :bundle do
    system("bundle install")
  end

  desc "Run the Continuous Integration build"
  task :run => ["ci:bundle", "db:migrate"] do
    Rake::Task["test:units"].invoke
  end
  
end