namespace :company1 do

  desc "Initialize company1 test data"
  task :init => [:users, :company, :services]

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
  end
  
  task :company do
    # Check to see if company 1 already exists. If so, don't continue
    @company1 = Company.find_by_subdomain('company1')
    if (@company1.nil?)
  
      # create subscriptions
      @subscription  = Subscription.create(:user => @johnny, :plan => @max_plan)
  
      puts "#{Time.now}: creating company1 company"
      # create test companies
      @company1        = Company.create(:name => "Company 1", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)
    else
      puts "#{Time.now}: company1 already exists"
    end
    # add manager role
    @johnny.grant_role('company manager', @company1)

    # add providers
    @company1.providers.push(@johnny) unless @company1.providers.include?(@johnny)
    @company1.providers.push(@mary) unless @company1.providers.include?(@mary)
  end
  
  task :services do
    puts "#{Time.now}: adding company1 services ..."

    # create services
    @mens_haircut    = @company1.services.find_by_name("Men's Haircut") || @company1.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00, :allow_custom_duration => false)
    @womens_haircut  = @company1.services.find_by_name("Women's Haircut") || @company1.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00, :allow_custom_duration => true)

    puts "#{Time.now}: adding company1 service providers ..."

    # add service providers
    @mens_haircut.providers.push(@johnny) unless @mens_haircut.providers.include?(@johnny)
    @womens_haircut.providers.push(@mary) unless @womens_haircut.providers.include?(@mary)

    puts "#{Time.now}: completed"
  end
end
