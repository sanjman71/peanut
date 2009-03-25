
namespace :noelrose do

  desc "Initialize noelrose test data"
  task :init => [:users, :services]

  task :users do

    puts "#{Time.now}: creating noelrose users"
  
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users  
    @erika          = User.create(:name => "Erika Maechtle", :email => "erika@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @erika.register!
    @erika.activate!
  
    # create subscriptions
    @subscription  = Subscription.create(:user => @erika, :plan => @max_plan)
  
    puts "#{Time.now}: creating noelrose company"
    # create test companies
    @noelrose        = Company.create(:name => "Noel Rose", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)

    # add user roles
    @erika.grant_role('company manager', @noelrose)
    @erika.grant_role('company employee', @noelrose)
    
  end
  
  task :services do
  
    puts "#{Time.now}: adding noelrose services ..."
    # create noelrose services, products
    @mens_haircut     = @noelrose.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00)
    @womens_haircut   = @noelrose.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00)
    @color1           = @noelrose.services.create(:name => "Single Process Color", :duration => 120, :mark_as => "work", :price => 65.00)
    @color2           = @noelrose.services.create(:name => "Touch-Up Color", :duration => 120, :mark_as => "work", :price => 45.00)
    @color3           = @noelrose.services.create(:name => "Glossing", :duration => 120, :mark_as => "work", :price => 25.00)

    puts "#{Time.now}: adding noelrose products ..."
    @shampoo          = @noelrose.products.create(:name => "Shampoo", :inventory => 5, :price => 10.00)
    @conditioner      = @noelrose.products.create(:name => "Conditioner", :inventory => 5, :price => 15.00)
    @pomade           = @noelrose.products.create(:name => "Pomade", :inventory => 5, :price => 12.00)

    puts "#{Time.now}: completed"
  end

end
