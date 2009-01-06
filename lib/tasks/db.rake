require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :peanut do
    
    desc "Initialize test data"
    task :init do
      puts "#{Time.now}: adding test data ..."
      
      # create test companies
      company1        = Company.create(:name => "Company 1", :time_zone => "Central Time (US & Canada)")
      noelrose        = Company.create(:name => "Noel Rose", :time_zone => "Central Time (US & Canada)")
    
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

      # create noelrose people, services, products
      noelrose.services.create(:name => Service::AVAILABLE, :duration => 0, :mark_as => "free", :price => 0.00)
      noelrose.services.create(:name => Service::UNAVAILABLE, :duration => 0, :mark_as => "busy", :price => 0.00)

      person1         = noelrose.people.create(:name => "Erika Maechtle")
      person2         = noelrose.people.create(:name => "Josie")
      
      mens_haircut    = noelrose.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00)
      womens_haircut  = noelrose.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00)
      color1          = noelrose.services.create(:name => "Single Process Color", :duration => 120, :mark_as => "work", :price => 65.00)
      color2          = noelrose.services.create(:name => "Touch-Up Color", :duration => 120, :mark_as => "work", :price => 45.00)
      color3          = noelrose.services.create(:name => "Glossing", :duration => 120, :mark_as => "work", :price => 25.00)

      shampoo         = noelrose.products.create(:name => "Shampoo", :inventory => 5, :price => 10.00)
      conditioner     = noelrose.products.create(:name => "Conditioner", :inventory => 5, :price => 15.00)
      pomade          = noelrose.products.create(:name => "Pomade", :inventory => 5, :price => 12.00)
      
      # add skillsets
      mens_haircut.resources.push(person1)
      mens_haircut.resources.push(person2)
      womens_haircut.resources.push(person1)
      womens_haircut.resources.push(person2)
      color1.resources.push(person1)
      color1.resources.push(person2)
      color2.resources.push(person1)
      color2.resources.push(person2)
      color3.resources.push(person1)
      color3.resources.push(person2)
      
      # create customers
      Customer.create(:name => "Sanjay Kapoor", :email => "sanjay@jarna.com", :phone => "6503876818")
      Customer.create(:name => "Killian Murphy", :email => "killian@killianmurphy.com", :phone => "6504502628")
      
      # Create admin users
      puts "adding admin user: admin@killianmurphy.com, password: peanut"
      a = User.create(:company_id => 0, :name => "Admin", :email => "admin@killianmurphy.com", :password => "peanut", :password_confirmation => "peanut")
      a.register!
      a.activate!
      a.grant_role('admin')

      puts "adding admin user: sanjay@jarna.com, password: peanut"
      a = User.create(:company_id => 0, :name => "Admin", :email => "sanjay@jarna.com", :password => "peanut", :password_confirmation => "peanut")
      a.register!
      a.activate!
      a.grant_role('admin')

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
