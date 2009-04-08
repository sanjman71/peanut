require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :init do
  
  desc "Initialize development data"
  task :dev_data  => ["rp:init", "plans:init", :admin_users, :companies]

  desc "Initialize production data"
  task :prod_data  => ["rp:init", "plans:init", :admin_users]
  
  desc "Initialize admin users"
  task :admin_users do 
    # Create admin users
    puts "adding admin user: admin@killianmurphy.com, password: peanut"
    a = User.create(:name => "Admin Killian", :email => "admin@killianmurphy.com", :phone => "6504502628",
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('admin')
    a.mobile_carrier = MobileCarrier.find_by_name("AT&T/Cingular")
    a.save

    puts "adding admin user: sanjay@jarna.com, password: peanut"
    a = User.create(:name => "Admin Sanjay", :email => "sanjay@jarna.com", :phone => "6503876818",
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('admin')
    a.mobile_carrier = MobileCarrier.find_by_name("Verizon Wireless")
    a.save
    
    puts "#{Time.now}: completed"
  end
  
  desc "Initialize regular users"
  task :regular_users do 
    # create company managers
    company1 = Company.find_by_name('Company 1')
    noelrose = Company.find_by_name('Noel Rose')
    
    puts "adding user: johnny@peanut.com, password: peanut as company manager for #{company1.name}"
    a = User.create(:name => "Johnny Smith", :email => "johnny@peanut.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('manager', company1)
    a.grant_role('provider', company1)

    puts "adding user: mary@peanut.com, password: peanut as company manager for #{company1.name}"
    a = User.create(:name => "Mary Jones", :email => "mary@peanut.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('provider', company1)
    
    puts "adding user: erika@peanut.com, password: peanut as company manager for #{noelrose.name}"
    a = User.create(:name => "Erika Maechtle", :email => "erika@peanut.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('manager', noelrose)
    a.grant_role('provider', noelrose)

    puts "#{Time.now}: completed"
  end

  task :companies => ["company1:init", "noelrose:init", "meatheads:init"]

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
