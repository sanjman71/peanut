require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :peanut do
    
    namespace :plans do
      
      desc "Initialize plans"
      task :init  => [:free, :basic, :premium, :max]

      desc "Initialize free plan"
      task :free do
        
        puts "creating free plan"
        p = Plan.create(
          :name => "Free!",
          :link_text => "free",
          :monthly_cost => 0.0,
          :cost_currency => "USD",
          :max_resources => 1,
          :max_services => 5,
          :max_products => 5,
          :max_appointments => 100,
          :max_locations => 1
        )
      end
      
      desc "Initialize basic plan"
      task :basic do
        
        puts "creating basic plan"
        p = Plan.create(
          :name => "Basic",
          :link_text => "basic",
          :monthly_cost => 10.0,
          :cost_currency => "USD",
          :max_resources => 5,
          :max_services => 20,
          :max_products => 50,
          :max_appointments => 5000,
          :max_locations => 1,
          :days_before_start_billing => 30,
          :months_between_bills => 1
        )
      end

      desc "Initialize premium plan"
      task :premium do
        
        puts "creating premium plan"
        p = Plan.create(
          :name => "Premium",
          :link_text => "premium",
          :monthly_cost => 30.0,
          :cost_currency => "USD",
          :max_resources => 20,
          :max_services => 50,
          :max_products => 100,
          :max_appointments => 10000,
          :max_locations => 3,
          :days_before_start_billing => 30,
          :months_between_bills => 1
        )
      end

      desc "Initialize max plan"
      task :max do
        
        puts "creating max plan"
        p = Plan.create(
          :name => "Max",
          :link_text => "max",
          :monthly_cost => 50.0,
          :cost_currency => "USD",
          :days_before_start_billing => 30,
          :months_between_bills => 1
        )
      end


    end
    
  end
  
end
