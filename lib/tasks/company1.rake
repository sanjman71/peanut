namespace :company1 do

  desc "Initialize company1 test data"
  task :init => [:users, :company, :services]
  task :destroy => [:company_destroy, :services_destroy, :users_destroy] # The services are destroyed when the company is destroyed

  task :users do
    puts "#{Time.now}: creating company1 users"
  
    @max_plan = Plan.find_by_name("Max") || Plan.first
  
    # create users
    if (@johnny = User.find_by_email("johnny@peanut.com") )
      puts "user: johnny@peanut.com already in db"
    else
      @johnny = User.create(:name => "Johnny Smith", :email => "johnny@peanut.com", :password => "peanut", :password_confirmation => "peanut")
      @johnny.register!
      @johnny.activate!
    end
                                
    if (@mary = User.find_by_email("mary@peanut.com") )
      puts "user: mary@peanut.com already in db"
    else
      @mary = User.create(:name => "Mary Jones", :email => "mary@peanut.com", :password => "peanut", :password_confirmation => "peanut")
      @mary.register!
      @mary.activate!
    end
  end
  
  task :users_destroy do
    if (@johnny = User.find_by_email("johnny@peanut.com") )
      puts "company1: destroying user id #{@johnny.id} email #{@johnny.email}"
      @johnny.destroy
    else
      puts "company1: didn't find user johnny@peanut.com"
    end
    if (@mary = User.find_by_email("mary@peanut.com") )
      puts "company1: destroying user id #{@mary.id} email #{@mary.email}"
      @mary.destroy
    else
      puts "company1: didn't find user mary@peanut.com"
    end
  end
  
  task :company do
    # Check to see if company 1 already exists. If so, don't continue
    @company1 = Company.find_by_subdomain('company1')

    if @company1.blank?
      puts "#{Time.now}: creating company1 company"
      @company1 = Company.create(:name => "Company 1", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)
    end

    if @company1.subscription.blank?
      # create subscription in 'active' state
      @subscription = @company1.create_subscription(:user => @johnny, :plan => @max_plan)
      @subscription.active!
    end

    # add manager role
    @johnny.grant_role('company manager', @company1)

    # add providers
    @company1.user_providers.push(@johnny) unless @company1.user_providers.include?(@johnny)
    @company1.user_providers.push(@mary) unless @company1.user_providers.include?(@mary)
  end
  
  # Destroying the company will also destroy the services and providers
  task :company_destroy do
    if (@company1 = Company.find_by_subdomain('company1'))
      puts "company1: destroying company id #{@company1.id} name #{@company1.name}"
      @company1.destroy(:all => true)
    else
      puts "company1: didn't find company1"
    end
  end
  
  task :services do
    puts "#{Time.now}: adding company1 services ..."

    @company1 = Company.find_by_subdomain('company1')

    # create services
    @mens_haircut    = @company1.services.find_by_name("Men's Haircut") || @company1.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00, :allow_custom_duration => false)
    @womens_haircut  = @company1.services.find_by_name("Women's Haircut") || @company1.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00, :allow_custom_duration => true)

    puts "#{Time.now}: adding company1 service providers ..."

    # add service providers
    @mens_haircut.user_providers.push(@johnny) unless @mens_haircut.user_providers.include?(@johnny)
    @womens_haircut.user_providers.push(@mary) unless @womens_haircut.user_providers.include?(@mary)

    puts "#{Time.now}: completed"
  end
  
  task :services_destroy do
    @company1 = Company.find_by_subdomain('company1')
    if @company1 && (@mens_haircut = @company1.services.find_by_name("Men's Haircut"))
      puts "company1: destroying service id #{@mens_haircut.id} name #{@mens_haircut.name}"
      @mens_haircut.destroy
    else
      puts "company1: didn't find service Men's Haircut"
    end
    if @company1 && (@womens_haircut = @company1.services.find_by_name("Women's Haircut"))
      puts "company1: destroying service id #{@womens_haircut.id} name #{@womens_haircut.name}"
      @womens_haircut.destroy
    else
      puts "company1: didn't find service Women's Haircut"
    end
  end
end
