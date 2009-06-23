require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :init do
  
  desc "Initialize development data"
  task :dev_data  => ["rp:init", "plans:init", :admin_users, :companies]

  desc "Initialize production data"
  task :prod_data  => ["rp:init", "plans:init", :admin_users]
  
  desc "Initialize admin users"
  task :admin_users do 
    # Create admin users
    if (User.find_by_email("admin@killianmurphy.com").nil? )
      puts "adding admin user: admin@killianmurphy.com, password: peanut"
      a = User.create(:name => "Admin Killian", :email => "admin@killianmurphy.com", :phone => "6504502628",
                      :password => "peanut", :password_confirmation => "peanut")
      a.register!
      a.activate!
      a.grant_role('admin')
      a.mobile_carrier = MobileCarrier.find_by_name("AT&T/Cingular")
      a.save
    else
      puts "admin user: admin@killianmurphy.com already in db"
    end

    if (User.find_by_email("sanjay@jarna.com").nil? )
      puts "adding admin user: sanjay@jarna.com, password: peanut"
      a = User.create(:name => "Admin Sanjay", :email => "sanjay@jarna.com", :phone => "6503876818",
                      :password => "peanut", :password_confirmation => "peanut")
      a.register!
      a.activate!
      a.grant_role('admin')
      a.mobile_carrier = MobileCarrier.find_by_name("Verizon Wireless")
      a.save
    else
      puts "admin user: sanjay@jarna.com already in db"
    end
    
    puts "#{Time.now}: completed"
  end
  
  task :companies => ["company1:init", "noelrose:init", "meatheads:init", "mctrucks:init"]

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
