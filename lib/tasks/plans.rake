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
          :name => "Free",
          :textid => "free",
          :cost => 0.0,
          :cost_currency => "USD",
          :max_resources => 1,
          :max_locations => 1
        )
      end
      
      desc "Initialize basic plan"
      task :basic do
        
        puts "creating basic plan"
        p = Plan.create(
          :name => "Basic",
          :textid => "basic",
          :cost => 10.0,
          :cost_currency => "USD",
          :max_resources => 5,
          :max_locations => 1,
          :days_to_first_bill => 30,
          :months_between_bills => 1
        )
      end

      desc "Initialize premium plan"
      task :premium do
        
        puts "creating premium plan"
        p = Plan.create(
          :name => "Premium",
          :textid => "premium",
          :cost => 30.0,
          :cost_currency => "USD",
          :max_resources => 20,
          :max_locations => 3,
          :days_to_first_bill => 30,
          :months_between_bills => 1
        )
      end

      desc "Initialize max plan"
      task :max do
        
        puts "creating max plan"
        p = Plan.create(
          :name => "Max",
          :textid => "max",
          :cost => 50.0,
          :cost_currency => "USD",
          :days_to_first_bill => 30,
          :months_between_bills => 1
        )
      end


    end
    
  end
  
end
