
namespace :meatheads do

  desc "Initialize meatheads test data"
  task :init => [:users, :company, :services]
  
  task :users do
  
    puts "#{Time.now}: creating meatheads users"
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users
  
    if (@meathead = User.find_by_email("meathead@peanut.com") )
      puts "user: meathead@peanut.com already in db"
    else
      @meathead       = User.create(:name => "Meathead Manager", :email => "meathead@peanut.com", 
                                    :password => "peanut", :password_confirmation => "peanut")
      @meathead.register!
      @meathead.activate!
    end

    if (@wimpy = User.find_by_email("wimpy@peanut.com") )
      puts "user: wimpy@peanut.com already in db"
    else
      @wimpy          = User.create(:name => "Wimpy Arms", :email => "wimpy@peanut.com", 
                                    :password => "peanut", :password_confirmation => "peanut")
      @wimpy.register!
      @wimpy.activate!
    end

    if (@skinny = User.find_by_email("skinny@peanut.com") )
      puts "user: skinny@peanut.com already in db"
    else
      @skinny         = User.create(:name => "Skinny Legs", :email => "skinny@peanut.com", 
                                    :password => "peanut", :password_confirmation => "peanut")
      @skinny.register!
      @skinny.activate!
    end
  
  end
  
  task :company do
    @meatheads = Company.find_by_subdomain('meatheads')
    if @meatheads.nil?
      # create subscriptions
      @subscription  = Subscription.create(:user => @meathead, :plan => @max_plan)
  
      puts "#{Time.now}: creating meatheads company"
      # create test companies
      @meatheads       = Company.create(:name => "Meat Heads", :time_zone => "Central Time (US & Canada)", :subscription => @subscription)

    end
    # add manager roles
    @meathead.grant_role('manager', @meatheads)

    # assign providers
    @meatheads.providers.push(@meathead) unless @meatheads.providers.include?(@meathead)
    @meatheads.providers.push(@wimpy) unless @meatheads.providers.include?(@wimpy)
    @meatheads.providers.push(@skinny) unless @meatheads.providers.include?(@skinny)
  end
  
  task :services do
  
    puts "#{Time.now}: adding meathead services ..."
  
    # create services
    @training         = @meatheads.services.find_by_name("Personal Training") || @meatheads.services.create(:name => "Personal Training", :duration => 60, :mark_as => "work", :price => 20.00, :allow_custom_duration => true)

    puts "#{Time.now}: adding meatheads service providers ..."

    # add service providers
    @training.providers.push(@wimpy) unless @training.providers.include?(@wimpy)
    @training.providers.push(@skinny) unless @training.providers.include?(@skinny)

    puts "#{Time.now}: completed"
  end

end
