require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :peanut do
    
    desc "Initialize test data"
    task :init do
      puts "#{Time.now}: adding test data ..."
      
      # create test companies
      company1 = Company.create(:name => "Company 1")
      company2 = Company.create(:name => "Company 2")
      company3 = Company.create(:name => "Company 3")
    
      # create basic services
      company1.services.create(:name => Service::AVAILABLE, :duration => 0, :mark_as => "free")
      company1.services.create(:name => Service::UNAVAILABLE, :duration => 0, :mark_as => "busy")
      company1.services.create(:name => "Haircut", :duration => 30, :mark_as => "work")
    
      # create basic resources
      company1.resources.create(:name => "Johnny")
      company1.resources.create(:name => "Mary")

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