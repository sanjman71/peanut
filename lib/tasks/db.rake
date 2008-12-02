require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :peanut do
    
    desc "Initialize test data"
    task :init do
      puts "#{Time.now}: adding test data ..."
      
      # create test companies
      company1 = Company.create(:name => "Company 1")
      company2 = Company.create(:name => "Company 2")
      company3 = Company.create(:name => "Noel Rose")
    
      # create company1 services and people
      company1.services.create(:name => Service::AVAILABLE, :duration => 0, :mark_as => "free", :price => 0.00)
      company1.services.create(:name => Service::UNAVAILABLE, :duration => 0, :mark_as => "busy", :price => 0.00)
      
      mens_haircut    = company1.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00)
      womens_haircut  = company1.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00)
      
      person1         = company1.people.create(:name => "Johnny")
      person2         = company1.people.create(:name => "Mary")
      
      # apply rules to what services can be performed by what resources
      mens_haircut.resources.push(person1)
      womens_haircut.resources.push(person2)

      # create company3 services and people
      company3.services.create(:name => Service::AVAILABLE, :duration => 0, :mark_as => "free", :price => 0.00)
      company3.services.create(:name => Service::UNAVAILABLE, :duration => 0, :mark_as => "busy", :price => 0.00)
      
      mens_haircut    = company3.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00)
      womens_haircut  = company3.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00)
      womens_color    = company3.services.create(:name => "Women's Color", :duration => 120, :mark_as => "work", :price => 100.00)
    
      person1         = company3.people.create(:name => "Erika Maechtle")
      person2         = company3.people.create(:name => "Josie")

      mens_haircut.resources.push(person1)
      mens_haircut.resources.push(person2)
      womens_haircut.resources.push(person1)
      womens_haircut.resources.push(person2)
      womens_color.resources.push(person1)
      womens_color.resources.push(person2)
      
      # create customers
      Customer.create(:name => "Sanjay Kapoor", :email => "sanjay@jarna.com", :phone => "6503876818")
      Customer.create(:name => "Killian Murphy", :email => "killian@killianmurphy.com", :phone => "6504502628")
      
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
          company.people.each do |person|
            1.upto(days) do |i|
              # free times from 8 am to 4 pm each day
              free_start_at = (Time.now + i.day).beginning_of_day + 8.hours
              free_end_at   = free_start_at + 8.hours
              
              begin
                AppointmentScheduler.create_free_appointment(company, person, free_start_at, free_end_at)
                puts "#{Time.now}: added #{company.name}, #{person.name} free time from #{free_start_at}-#{free_end_at}"
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
