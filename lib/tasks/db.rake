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
      Job.create(:name => Job::AVAILABLE, :duration => 0, :mark_as => "free")
      Job.create(:name => Job::UNAVAILABLE, :duration => 0, :mark_as => "busy")
      Job.create(:name => "Haircut", :duration => 30, :mark_as => "busy")
    
      # create basic resources
      Resource.create(:name => "Johnny", :company => Company.find_by_name("Company 1"))
      Resource.create(:name => "Mary", :company => Company.find_by_name("Company 1"))

      puts "#{Time.now}: completed"
    end
    
    namespace :freetime do
      
      # Initialize some free time
      desc "Initialize freetime for companies, resources"
      task :init, :days do |t, args|
        days = args.days.to_i
        days = 1 if days == 0
        
        puts "#{Time.now}: adding #{days} days of free time for all companies, resources ..."
        
        Company.all.each do |company|
          company.resources.each do |resource|
            1.upto(days) do |i|
              start_at = (Time.now + i.day).beginning_of_day
              end_at   = start_at + 24.hours
              begin
                Appointment.create_free_time(company, resource, start_at, end_at)
                puts "#{Time.now}: added #{company.name}, #{resource.name} free time from #{start_at}-#{end_at}"
              rescue TimeslotNotEmpty
                # skip
              end
            end
          end
        end
        
        puts "#{Time.now}: completed"
      end
      
    end # freetime namespace
    
  end # peanut namespace
end # db namespace