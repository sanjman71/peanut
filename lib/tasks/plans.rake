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
          :enabled => true,
          :cost => 0,
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
          :enabled => true,
          :cost => 1000,
          :cost_currency => "USD",
          :max_resources => 5,
          :max_locations => 1,
          :start_billing_in_time_amount => 1,
          :start_billing_in_time_unit => "months",
          :between_billing_time_amount => 1,
          :between_billing_time_unit => "months"
        )
      end

      desc "Initialize premium plan"
      task :premium do
        
        puts "creating premium plan"
        p = Plan.create(
          :name => "Premium",
          :enabled => true,
          :cost => 3000,
          :cost_currency => "USD",
          :max_resources => 20,
          :max_locations => 3,
          :start_billing_in_time_amount => 1,
          :start_billing_in_time_unit => "months",
          :between_billing_time_amount => 1,
          :between_billing_time_unit => "months"
        )
      end

      desc "Initialize max plan"
      task :max do
        
        puts "creating max plan"
        p = Plan.create(
          :name => "Max",
          :enabled => true,
          :cost => 5000,
          :cost_currency => "USD",
          :start_billing_in_time_amount => 1,
          :start_billing_in_time_unit => "months",
          :between_billing_time_amount => 1,
          :between_billing_time_unit => "months"
        )
      end


    end
    
  end
  
end
