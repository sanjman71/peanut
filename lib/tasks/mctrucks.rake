namespace :mctrucks do

  desc "Initialize mctrucks test data"
  task :init => [:users_resources, :company, :services]

  task :users_resources do
    puts "#{Time.now}: creating mctrucks users & resources"
  
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users  
    if (@owner = User.find_by_email("mrtrucks@peanut.com") )
      puts "user: mrtrucks@peanut.com already in db"
    else
      @owner          = User.create(:name => "Mr Trucks", :email => "mrtrucks@peanut.com", 
                                    :password => "peanut", :password_confirmation => "peanut")
      @owner.register!
      @owner.activate!
    end
        
    if @moving_van = Resource.find_by_name("Moving Van")
      puts "resource: moving van already in db"
    else
      # create resources
      @moving_van = Resource.create(:name => "Moving Van")
      @mctrucks.providers.push(@moving_van)
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

    # add as company provider
    @mctrucks.providers.push(@owner) unless @mctrucks.providers.include?(@owner)

  end
  
  task :services do
    puts "#{Time.now}: adding mctrucks services ..."

    # create services
    @rental = @mctrucks.services.find_by_name("Rental") || @mctrucks.services.create(:name => "Rental", :duration => 60, :mark_as => "work", :price => 50.00)

    # add service providers
    @rental.providers.push(@moving_van) unless @rental.providers.include?(@moving_van)
  
    puts "#{Time.now}: completed"
  end
  
end
