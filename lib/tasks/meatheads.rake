
namespace :meatheads do

  desc "Initialize meatheads test data"
  task :init => [:users, :services]
  
  task :users do
  
    puts "#{Time.now}: creating meatheads users"
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users
  
    @meathead       = User.create(:name => "Meathead Manager", :email => "meathead@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut")
    @meathead.register!
    @meathead.activate!

    @wimpy          = User.create(:name => "Wimpy Arms", :email => "wimpy@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut")
    @wimpy.register!
    @wimpy.activate!

    @skinny         = User.create(:name => "Skinny Legs", :email => "skinny@peanut.com", 
                                  :password => "peanut", :password_confirmation => "peanut")
    @skinny.register!
    @skinny.activate!
  
    # create subscriptions
    @subscription  = Subscription.create(:user => @meathead, :plan => @max_plan)
  
    puts "#{Time.now}: creating meatheads company"
    # create test companies
    @meatheads       = Company.create(:name => "Meat Heads", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)

    # add manager roles
    @meathead.grant_role('manager', @meatheads)
  end
  
  task :services do
  
    puts "#{Time.now}: adding meathead services ..."
  
    # assign providers
    @meatheads.providers.push(@meathead)
    @meatheads.providers.push(@wimpy)
    @meatheads.providers.push(@skinny)

    # create services
    @training         = @meatheads.services.create(:name => "Personal Training", :duration => 60, :mark_as => "work", :price => 20.00, :allow_custom_duration => true)

    puts "#{Time.now}: adding meatheads service providers ..."

    # add service providers
    @training.providers.push(@wimpy)
    @training.providers.push(@skinny)

    puts "#{Time.now}: completed"
  end

end
