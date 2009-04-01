namespace :company1 do

  desc "Initialize company1 test data"
  task :init => [:users, :services]

  task :users do
    puts "#{Time.now}: creating company1 users"
  
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users
    @johnny         = User.create(:name => "Johnny Smith", :email => "johnny@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @johnny.register!
    @johnny.activate!
                                
    @mary           = User.create(:name => "Mary Jones", :email => "mary@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @mary.register!
    @mary.activate!
  
    # create subscriptions
    @subscription  = Subscription.create(:user => @johnny, :plan => @max_plan)
  
    puts "#{Time.now}: creating company1 company"
    # create test companies
    @company1        = Company.create(:name => "Company 1", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)

    # add user roles
    @johnny.grant_role('company manager', @company1)
    @johnny.grant_role('company employee', @company1)
    @mary.grant_role('company employee', @company1)
    
  end
  
  task :services do    
  
    puts "#{Time.now}: adding company1 services ..."
  
    # assign schedulables
    @company1.schedulables.push(@johnny)
    @company1.schedulables.push(@mary)
  
    # create services
    @mens_haircut    = @company1.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00, :allow_custom_duration => false)
    @womens_haircut  = @company1.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00, :allow_custom_duration => true)

    puts "#{Time.now}: adding company1 service providers ..."

    # add service providers
    @mens_haircut.schedulables.push(@johnny)
    @womens_haircut.schedulables.push(@mary)

    puts "#{Time.now}: completed"
  end
end