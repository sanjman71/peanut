require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :plans do
  
  desc "Initialize plans"
  task :init  => [:free, :basic, :premium, :max]

  desc "Initialize free plan"
  task :free do
    
    puts "creating free plan"
    p = Plan.create(
      :name => "Free",
      :textid => "free",
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
      :textid => "basic",
      :cost => 1000,
      :cost_currency => "USD",
      :max_resources => 5,
      :max_locations => 1,
      :start_billing_in_time_amount => 30,
      :start_billing_in_time_unit => "days",
      :between_billing_time_amount => 1,
      :between_billing_time_unit => "months"
    )
  end

  desc "Initialize premium plan"
  task :premium do
    
    puts "creating premium plan"
    p = Plan.create(
      :name => "Premium",
      :textid => "premium",
      :cost => 3000,
      :cost_currency => "USD",
      :max_resources => 20,
      :max_locations => 3,
      :start_billing_in_time_amount => 30,
      :start_billing_in_time_unit => "days",
      :between_billing_time_amount => 1,
      :between_billing_time_unit => "months"
    )
  end

  desc "Initialize max plan"
  task :max do
    
    puts "creating max plan"
    p = Plan.create(
      :name => "Max",
      :textid => "max",
      :cost => 5000,
      :cost_currency => "USD",
      :start_billing_in_time_amount => 30,
      :start_billing_in_time_unit => "days",
      :between_billing_time_amount => 1,
      :between_billing_time_unit => "months"
    )
  end

end

