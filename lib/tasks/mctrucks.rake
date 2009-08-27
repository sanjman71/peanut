namespace :mctrucks do

  desc "Initialize mctrucks test data"
  task :init => [:users_resources, :company, :services]
  task :destroy => [:company_destroy, :services_destroy, :users_resources_destroy]

  task :users_resources do
    puts "#{Time.now}: creating mctrucks users & resources"
  
    @max_plan = Plan.find_by_name("Max") || Plan.first
    @mctrucks = Company.find_by_subdomain('mctrucks')
  
    # create users  
    if (@owner = User.find_by_email("mrtrucks@peanut.com") )
      puts "user: mrtrucks@peanut.com already in db"
    else
      @owner          = User.create(:name => "Mr Trucks", :email => "mrtrucks@peanut.com", 
                                    :password => "peanut", :password_confirmation => "peanut")
      @owner.register!
      @owner.activate!
    end
        
    if @mctrucks && (@moving_van = @mctrucks.providers.find_by_name("Moving Van"))
      puts "resource: moving van already in db"
    else
      # create resources
      @moving_van = Resource.create(:name => "Moving Van")
    end

  end
  
  task :users_resources_destroy do
    @mctrucks = Company.find_by_subdomain('mctrucks')
    if (@owner = User.find_by_email("mrtrucks@peanut.com") )
      puts "mctrucks: destroying user id #{@owner.id} email #{@owner.email}"
      @owner.destroy
    else
      puts "mctrucks: didn't find user mrtrucks@peanut.com"
    end
    if @mctrucks && (@moving_van = @mctrucks.providers.find_by_name("Moving Van"))
      puts "mctrucks: destroying resource id #{@moving_van.id} name #{@moving_van.name}"
      @moving_van.destroy
    else
      puts "mctrucks: didn't find resource Moving Van"
    end
  end
  
  task :company do

    # Check to see if company 1 already exists. If so, don't continue
    @mctrucks = Company.find_by_subdomain('mctrucks')
    if (@mctrucks.nil?)  
  
      # create subscriptions
      @subscription = Subscription.create(:user => @owner, :plan => @max_plan)
  
      puts "#{Time.now}: creating mctrucks company"
      # create test companies
      @mctrucks     = Company.create(:name => "McTrucks", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)

    end
    # add manager roles
    @owner.grant_role('company manager', @mctrucks)

    # add company providers
    @mctrucks.providers.push(@owner) unless @mctrucks.providers.include?(@owner)
    @mctrucks.providers.push(@moving_van)

  end
  
  # Destroying the company will also destroy the services and providers
  task :company_destroy do
    if (@mctrucks = Company.find_by_subdomain('mctrucks'))
      puts "mctrucks: destroying company id #{@mctrucks.id} name #{@mctrucks.name}"
      @mctrucks.destroy(:all => true)
    else
      puts "mctrucks: didn't find mctrucks"
    end
  end
  
  task :services do
    puts "#{Time.now}: adding mctrucks services ..."

    # create services
    @rental = @mctrucks.services.find_by_name("Rental") || @mctrucks.services.create(:name => "Rental", :duration => 60, :mark_as => "work", :price => 50.00)

    # add service providers
    @rental.providers.push(@moving_van) unless @rental.providers.include?(@moving_van)
  
    puts "#{Time.now}: completed"
  end
  
  task :services_destroy do
    @mctrucks = Company.find_by_subdomain('mctrucks')
    if @mctrucks && (@rental = @mctrucks.services.find_by_name("Rental"))
      puts "mctrucks: destroying service id #{@rental.id} name #{@rental.name}"
      @rental.destroy
    else
      puts "mctrucks: didn't find service Rental"
    end
  end
  
end
