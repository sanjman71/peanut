namespace :company1 do

  desc "Initialize company1 test data"
  task :init => [:users, :services]

  task :users do
    puts "#{Time.now}: creating company1 users"
  
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users
    if (@johnny = User.find_by_email("johnny@peanut.com") )
      puts "user: johnny@peanut.com already in db"
    else
      @johnny         = User.create(:name => "Johnny Smith", :email => "johnny@peanut.com", 
                                    :password => "peanut", :password_confirmation => "peanut")
      @johnny.register!
      @johnny.activate!
    end
                                
    if (@mary = User.find_by_email("mary@peanut.com") )
      puts "user: mary@peanut.com already in db"
    else
      @mary           = User.create(:name => "Mary Jones", :email => "mary@peanut.com", 
                                    :password => "peanut", :password_confirmation => "peanut")
      @mary.register!
      @mary.activate!
    end
  
    # create subscriptions
    @subscription  = Subscription.create(:user => @johnny, :plan => @max_plan)
  
    puts "#{Time.now}: creating company1 company"
    # create test companies
    @company1        = Company.create(:name => "Company 1", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)

    # add manager role
    @johnny.grant_role('manager', @company1)

    # add providers
    @company1.providers.push(@johnny)
    @company1.providers.push(@mary)
  end
  
  task :services do    
    puts "#{Time.now}: adding company1 services ..."
  
    # create services
    @mens_haircut    = @company1.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00, :allow_custom_duration => false)
    @womens_haircut  = @company1.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00, :allow_custom_duration => true)

    puts "#{Time.now}: adding company1 service providers ..."

    # add service providers
    @mens_haircut.providers.push(@johnny)
    @womens_haircut.providers.push(@mary)

    puts "#{Time.now}: completed"
  end
end
