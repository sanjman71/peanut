require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  

  desc "Import basic test data"
  task :import_test_data do
    # create test companies
    Company.create(:name => "Company 1")
    Company.create(:name => "Company 2")
    Company.create(:name => "Company 3")
    
    # create basic jobs
    Job.create(:name => Job.available, :duration => 0)
    Job.create(:name => Job.unavailable, :duration => 0)
  end
  
end