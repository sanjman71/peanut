require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :plans do
  
  desc "Initialize plans"
  task :init  => [:indy, :basic, :premium, :max]

  desc "Initialize indy plan"
  task :indy do
    
    puts "creating indy plan"
    p = Plan.create(
      :name => "Indy",
      :enabled => true,
      :cost => 500,
      :cost_currency => "USD",
      :max_providers => 1,
      :max_locations => 1,
      :start_billing_in_time_amount => 1,
      :start_billing_in_time_unit => "months",
      :between_billing_time_amount => 1,
      :between_billing_time_unit => "months"
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
      :max_providers => 5,
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
      :max_providers => 20,
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

