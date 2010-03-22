namespace :db do
  namespace :test do
   
    desc "One-time initialization of the test database"
    task :load_badges => [ "db:test:prepare" ] do
      ActiveRecord::Base.establish_connection(:test)
      puts "loading badges"
      BadgesInit.roles_privileges
    end
  end
end