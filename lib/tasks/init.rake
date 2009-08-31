require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require File.expand_path(File.dirname(__FILE__) + "/../badges_init")
require File.expand_path(File.dirname(__FILE__) + "/../demos")

namespace :init do
  
  desc "Initialize development data"
  task :dev_data  => [:roles_privs, "plans:init", :create_companies]
  
  desc "Initialize production data"
  task :prod_data  => [:roles_privs, "plans:init"]

  desc "Initialize roles & privileges"
  task :roles_privs do
    BadgesInit.roles_privileges
  end
  
  # desc "Initialize admin users"
  # task :admin_users do 
  #   # Create admin users
  #   if (User.find_by_email("admin@killianmurphy.com").nil? )
  #     puts "adding admin user: admin@killianmurphy.com, password: peanut"
  #     a = User.create(:name => "Admin Killian", :email => "admin@killianmurphy.com", :password => "peanut", :password_confirmation => "peanut")
  #     a.register!
  #     a.activate!
  #     a.grant_role('admin')
  #     a.save
  #     a.phone_numbers.create(:name => "Mobile", :address => "6504502628")
  #   else
  #     puts "admin user: admin@killianmurphy.com already in db"
  #   end
  # 
  #   if (User.find_by_email("sanjay@jarna.com").nil? )
  #     puts "adding admin user: sanjay@jarna.com, password: peanut"
  #     a = User.create(:name => "Admin Sanjay", :email => "sanjay@jarna.com", :password => "peanut", :password_confirmation => "peanut")
  #     a.register!
  #     a.activate!
  #     a.grant_role('admin')
  #     a.save
  #     a.phone_numbers.create(:name => "Mobile", :address => "6503876818")
  #   else
  #     puts "admin user: sanjay@jarna.com already in db"
  #   end
  #   
  #   puts "#{Time.now}: completed"
  # end
  
  desc "Create Companies"
  task :create_companies do
    m = Meatheads.new
    m.create
    t = Mctrucks.new
    t.create
  end

  desc "Destroy companies"
  task :destroy_companies do
    m = Meatheads.new
    m.destroy
    t = Mctrucks.new
    t.destroy
  end
  
  # task :free_service do 
  #   # create free service used by all companies
  #   puts "adding free service, used by all companies"
  #   Service.create(:name => Service::AVAILABLE, :duration => 0, :mark_as => "free", :price => 0.00)
  # end

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
