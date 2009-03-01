require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :init do
  
  desc "Initialize development data"
  task :dev_data  => ["rp:init", "plans:init", :admin_users, :regular_users, :companies]

  desc "Initialize production data"
  task :prod_data  => ["rp:init", "plans:init", :admin_users]
  
  desc "Initialize admin users"
  task :admin_users do 
    # Create admin users
    puts "adding admin user: admin@killianmurphy.com, password: peanut"
    a = User.create(:name => "Admin", :email => "admin@killianmurphy.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('admin')

    puts "adding admin user: sanjay@jarna.com, password: peanut"
    a = User.create(:name => "Admin", :email => "sanjay@jarna.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('admin')
    
    puts "#{Time.now}: completed"
  end
  
  desc "Initialize regular users"
  task :regular_users do 
    # Create admin users
    puts "adding user: johnny@peanut.com, password: peanut"
    a = User.create(:name => "Johnny Smith", :email => "johnny@peanut.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!

    a.grant_role('company manager', Company.find_by_name('Company 1'))

    puts "adding user: mary@peanut.com, password: peanut"
    a = User.create(:name => "Mary Jones", :email => "mary@peanut.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    
    a.grant_role('company employee', Company.find_by_name('Company 1'))
    
    puts "adding user: erika@peanut.com, password: peanut"
    a = User.create(:name => "Erika Maechtle", :email => "erika@peanut.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    
    a.grant_role('company manager', Company.find_by_name('Noel Rose'))

    puts "#{Time.now}: completed"
  end

  desc "Initialize companies used as test data"
  task :companies do
    puts "#{Time.now}: adding test data ..."
  
    puts "#{Time.now}: adding companies company1 and noelrose ..."
    # create test companies
    company1        = Company.create(:name => "Company 1", :time_zone => "Central Time (US & Canada)")
    noelrose        = Company.create(:name => "Noel Rose", :time_zone => "Central Time (US & Canada)")
    company1.save
    noelrose.save

    puts "#{Time.now}: adding company1 services and people ..."
    # create company1 services and people
    mens_haircut    = company1.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00)
    womens_haircut  = company1.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00)
  
    person1         = company1.people.create(:name => "Johnny")
    person2         = company1.people.create(:name => "Mary")
  
    # apply rules to what services can be performed by what resources
    mens_haircut.resources.push(person1)
    womens_haircut.resources.push(person2)

    puts "#{Time.now}: adding noelrose services and people ..."
    # create noelrose people, services, products
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
  
    puts "#{Time.now}: adding skillsets ..."
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
    
    puts "#{Time.now}: adding company plans and account owners ..."
    
    plans     = Plan.order_by_cost
    free     = plans[0]
    basic    = plans[1]
    premium  = plans[2]
    max      = plans[3]
    
    u1        = User.find_by_email("admin@killianmurphy.com")
    u2        = User.find_by_email("sanjay@jarna.com")

    [{:company => company1, :user => u1, :plan => basic},
     {:company => noelrose, :user => u2, :plan => premium}].each do |hash|
       # create subscription
       subscription = Subscription.create(:user => hash[:user], :plan => hash[:plan], :company => hash[:company])
       
       # authorize bogus, but valid credit card
       payment      = subscription.authorize(bogus_credit_card)
    end

    puts "#{Time.now}: completed"
  end

end # init namespace
  
def bogus_credit_card
  ActiveMerchant::Billing::CreditCard.new({ 
    :number => '4242424242424242', 
    :first_name => 'Sanjay', 
    :last_name  => 'Peanut', 
    :month      => '8', 
    :year       => "#{ Time.now.year + 1 }", 
    :verification_value => '123', 
    :type       => 'master' 
  })
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