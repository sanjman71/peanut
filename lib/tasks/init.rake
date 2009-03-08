require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require 'test/factories'

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
    a.grant_role('company manager', company1)

    puts "adding user: mary@peanut.com, password: peanut as company manager for #{company1.name}"
    a = User.create(:name => "Mary Jones", :email => "mary@peanut.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('company employee', company1)
    
    puts "adding user: erika@peanut.com, password: peanut as company manager for #{noelrose.name}"
    a = User.create(:name => "Erika Maechtle", :email => "erika@peanut.com", 
                    :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    a.register!
    a.activate!
    a.grant_role('company manager', noelrose)

    puts "#{Time.now}: completed"
  end

  desc "Initialize companies used as test data"
  task :companies do
    puts "#{Time.now}: adding test data ..."
  
    puts "#{Time.now}: adding companies company1, noelrose, meatheads ..."
    
    @max_plan       = Plan.find_by_name("Max") || Plan.first
    
    # create users
    @johnny         = User.create(:name => "Johnny Smith", :email => "johnny@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @johnny.register!
    @johnny.activate!
                                  
    @mary           = User.create(:name => "Mary Jones", :email => "mary@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @mary.register!
    @mary.activate!
    
    @erika          = User.create(:name => "Erika Maechtle", :email => "erika@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @erika.register!
    @erika.activate!
    
    @meathead       = User.create(:name => "Meathead Manager", :email => "meathead@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @meathead.register!
    @meathead.activate!

    @wimpy          = User.create(:name => "Wimpy Arms", :email => "wimpy@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @wimpy.register!
    @wimpy.activate!

    @skinny         = User.create(:name => "Skinny Legs", :email => "skinny@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @skinny.register!
    @skinny.activate!
    
    # create subscriptions
    @subscription1  = Subscription.new(:user => @johnny, :plan => @max_plan)
    @subscription2  = Subscription.new(:user => @johnny, :plan => @max_plan)
    @subscription3  = Subscription.new(:user => @meathead, :plan => @max_plan)
    
    # create test companies
    @company1        = Company.create(:name => "Company 1", :time_zone => "Central Time (US & Canada)", :subscription => @subscription1)
    @noelrose        = Company.create(:name => "Noel Rose", :time_zone => "Central Time (US & Canada)", :subscription => @subscription2)
    @meatheads       = Company.create(:name => "Meat Heads", :time_zone => "Central Time (US & Canada)", :subscription => @subscription3)

    # add user roles
    @johnny.grant_role('company manager', @company1)
    @mary.grant_role('company employee', @company1)
    @erika.grant_role('company manager', @noelrose)
    @meathead.grant_role('company manager', @meatheads)
    @wimpy.grant_role('company employee', @meatheads)
    @skinny.grant_role('company employee', @meatheads)
    
    puts "#{Time.now}: adding company1 services and products ..."
    
    # assign schedulables
    @company1.schedulables.push(@johnny)
    @company1.schedulables.push(@mary)
    
    # create services
    @mens_haircut    = @company1.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00, :allow_custom_duration => false)
    @womens_haircut  = @company1.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00, :allow_custom_duration => true)
  
    puts "#{Time.now}: adding company1 service providers ..."
  
    # add service providers
    @mens_haircut.schedulables.push(@johnny)
    @womens_haircut.schedulables.push(@mary)

    puts "#{Time.now}: adding noelrose services and products ..."
    # create noelrose services, products
    @mens_haircut     = @noelrose.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00)
    @womens_haircut   = @noelrose.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00)
    @color1           = @noelrose.services.create(:name => "Single Process Color", :duration => 120, :mark_as => "work", :price => 65.00)
    @color2           = @noelrose.services.create(:name => "Touch-Up Color", :duration => 120, :mark_as => "work", :price => 45.00)
    @color3           = @noelrose.services.create(:name => "Glossing", :duration => 120, :mark_as => "work", :price => 25.00)

    @shampoo          = @noelrose.products.create(:name => "Shampoo", :inventory => 5, :price => 10.00)
    @conditioner      = @noelrose.products.create(:name => "Conditioner", :inventory => 5, :price => 15.00)
    @pomade           = @noelrose.products.create(:name => "Pomade", :inventory => 5, :price => 12.00)
  
    puts "#{Time.now}: adding meathead services and products ..."
    
    # assign schedulables
    @meatheads.schedulables.push(@meathead)

    # create services
    @training         = @meatheads.services.create(:name => "Personal Training", :duration => 60, :mark_as => "work", :price => 20.00, :allow_custom_duration => true)
  
    # add service providers
    @training.schedulables.push(@wimpy)
    @training.schedulables.push(@skinny)
  
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
