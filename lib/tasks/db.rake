require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :peanut do
    
    desc "Initialize test data"
    task :init do
      puts "#{Time.now}: adding test data ..."
      
      # create test companies
      Company.create(:name => "Company 1")
      Company.create(:name => "Company 2")
      Company.create(:name => "Company 3")
    
      # create basic jobs
      Job.create(:name => Job::AVAILABLE, :duration => 0, :schedule_as => "free")
      Job.create(:name => Job::UNAVAILABLE, :duration => 0, :schedule_as => "busy")
      Job.create(:name => "Haircut", :duration => 30, :schedule_as => "busy")
    
      # create basic resources
      Resource.create(:name => "Johnny", :company => Company.find_by_name("Company 1"))
      Resource.create(:name => "Mary", :company => Company.find_by_name("Company 1"))

      puts "#{Time.now}: completed"
    end
    
  end
end