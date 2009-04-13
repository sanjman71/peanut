namespace :mctrucks do

  desc "Initialize mctrucks test data"
  task :init => [:users, :services]

  task :users do
    puts "#{Time.now}: creating mctrucks users"
  
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users  
    @owner          = User.create(:name => "Mr Trucks", :email => "mrtrucks@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut", :invitation_id => 0)
    @owner.register!
    @owner.activate!
  
    # create subscriptions
    @subscription = Subscription.create(:user => @owner, :plan => @max_plan)
  
    puts "#{Time.now}: creating mctrucks company"
    # create test companies
    @mctrucks     = Company.create(:name => "McTrucks", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)

    # add manager roles
    @owner.grant_role('manager', @mctrucks)
    
    # add as company provider
    @mctrucks.providers.push(@owner)
  end
  
  task :services do
    puts "#{Time.now}: adding mctrucks services and resources ..."

    # create resources
    @moving_van = Resource.create(:name => "Moving Van")
    @mctrucks.providers.push(@moving_van)
    
    # create services
    @rental = @mctrucks.services.create(:name => "Rental", :duration => 60, :mark_as => "work", :price => 50.00)

    # add service providers
    @rental.providers.push(@moving_van)
    
    puts "#{Time.now}: completed"
  end
  
end
