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
  
  desc "Create Demos"
  task :create_demos do
    m = Meatheads.new
    m.create
    t = Mctrucks.new
    t.create
    s = MarysSalonAndSpa.new
    s.create
  end

  desc "Destroy Demos"
  task :destroy_demos do
    m = Meatheads.new
    m.destroy
    t = Mctrucks.new
    t.destroy
    s = MarysSalonAndSpa.new
    s.destroy
  end
  
end
  
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
