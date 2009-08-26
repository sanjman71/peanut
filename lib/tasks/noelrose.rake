namespace :noelrose do

  desc "Initialize noelrose test data"
  task :init => [:users, :company, :services]
  task :destroy => [:company_destroy, :services_destroy, :users_destroy] # The services are destroyed when the company is destroyed

  task :users do

    puts "#{Time.now}: creating noelrose users"
  
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users  
    if (@erika = User.find_by_email("erika@peanut.com") )
      puts "user: erika@peanut.com already in db"
    else
      @erika          = User.create(:name => "Erika Maechtle", :email => "erika@peanut.com", 
                                    :password => "peanut", :password_confirmation => "peanut")
      @erika.register!
      @erika.activate!
    end
    
  end
  
  task :users_destroy do
    if (@erika = User.find_by_email("erika@peanut.com") )
      puts "noelrose: destroying user id #{@erika.id} email #{@erika.email}"
      @erika.destroy
    else
      puts "noelrose: didn't find user erika@peanut.com"
    end
  end
  
  task :company do
  
    @noelrose = Company.find_by_subdomain('noelrose')
    if (@noelrose.nil?)  
      # create subscriptions
      @subscription = Subscription.create(:user => @erika, :plan => @max_plan)
  
      puts "#{Time.now}: creating noelrose company"
      # create test companies
      @noelrose     = Company.create(:name => "Noel Rose", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)
    end

    # add manager roles
    @erika.grant_role('company manager', @noelrose)

    # assign providers
    @noelrose.providers.push(@erika) unless @noelrose.providers.include?(@erika)
    
  end
  
  # Destroying the company will also destroy the services and providers
  task :company_destroy do
    if (@noelrose = Company.find_by_subdomain('noelrose'))
      puts "noelrose: destroying company id #{@noelrose.id} name #{@noelrose.name}"
      @noelrose.destroy(:all => true)
    else
      puts "noelrose: didn't find noelrose"
    end
  end
    
  task :services do
  
    puts "#{Time.now}: adding noelrose services ..."

    # create noelrose services, products
    @mens_haircut     = @noelrose.services.find_by_name("Men's Haircut") || @noelrose.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00)
    @womens_haircut   = @noelrose.services.find_by_name("Women's Haircut") || @noelrose.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00)
    @color1           = @noelrose.services.find_by_name("Single Process Color") || @noelrose.services.create(:name => "Single Process Color", :duration => 120, :mark_as => "work", :price => 65.00)
    @color2           = @noelrose.services.find_by_name("Touch-Up Color") || @noelrose.services.create(:name => "Touch-Up Color", :duration => 120, :mark_as => "work", :price => 45.00)
    @color3           = @noelrose.services.find_by_name("Glossing") || @noelrose.services.create(:name => "Glossing", :duration => 120, :mark_as => "work", :price => 25.00)

    puts "#{Time.now}: adding noelrose products ..."
    @shampoo          = @noelrose.products.find_or_create_by_name(:name => "Shampoo", :inventory => 5, :price => 10.00)
    @conditioner      = @noelrose.products.find_or_create_by_name(:name => "Conditioner", :inventory => 5, :price => 15.00)
    @pomade           = @noelrose.products.find_or_create_by_name(:name => "Pomade", :inventory => 5, :price => 12.00)

    puts "#{Time.now}: completed"
  end

  task :services_destroy do
    @noelrose = Company.find_by_subdomain('noelrose')
    if @noelrose && (@mens_haircut = @noelrose.services.find_by_name("Men's Haircut"))
      puts "noelrose: destroying service id #{@mens_haircut.id} name #{@mens_haircut.name}"
      @mens_haircut.destroy
    else
      puts "noelrose: didn't find service Men's Haircut"
    end
    if @noelrose && (@womens_haircut = @noelrose.services.find_by_name("Women's Haircut"))
      puts "noelrose: destroying service id #{@womens_haircut.id} name #{@womens_haircut.name}"
      @womens_haircut.destroy
    else
      puts "noelrose: didn't find service Women's Haircut"
    end
    if @noelrose && (@color1 = @noelrose.services.find_by_name("Single Process Color"))
      puts "noelrose: destroying service id #{@color1.id} name #{@color1.name}"
      @color1.destroy
    else
      puts "noelrose: didn't find service Single Process Color"
    end
    if @noelrose && (@color2 = @noelrose.services.find_by_name("Touch-Up Color"))
      puts "noelrose: destroying service id #{@color2.id} name #{@color2.name}"
      @color2.destroy
    else
      puts "noelrose: didn't find service Touch-Up Color"
    end
    if @noelrose && (@color3 = @noelrose.services.find_by_name("Glossing"))
      puts "noelrose: destroying service id #{@color3.id} name #{@color3.name}"
      @color3.destroy
    else
      puts "noelrose: didn't find service Single Process Color"
    end
  end

end
