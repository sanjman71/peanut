require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require File.expand_path(File.dirname(__FILE__) + "/../badges_init")
require File.expand_path(File.dirname(__FILE__) + "/../demos")

namespace :init do
  
  desc "Initialize development data"
  task :dev_data  => [:roles_privs, "plans:init", :create_demos]
  
  desc "Initialize production data"
  task :prod_data  => [:roles_privs, "plans:init"]

  desc "Initialize roles & privileges"
  task :roles_privs do
    BadgesInit.roles_privileges
  end
  
  desc "Rebuild Demos"
  task :rebuild_demos => [:destroy_demos, :create_demos]
  
  desc "Create Demos"
  task :create_demos => [:create_meatheads, :create_mctrucks, :create_maryssalon]

  desc "Destroy Demos"
  task :destroy_demos => [:destroy_meatheads, :destroy_mctrucks, :destroy_maryssalon]
  
  task :create_meatheads do
    m = Meatheads.new
    m.create
  end
  
  task :destroy_meatheads do
    m = Meatheads.new
    m.destroy
  end
  
  task :create_mctrucks do
    t = Mctrucks.new
    t.create
  end
  
  task :destroy_mctrucks do
    t = Mctrucks.new
    t.destroy
  end
  
  task :create_maryssalon do
    s = MarysSalonAndSpa.new
    s.create
  end
  
  task :destroy_maryssalon do
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
