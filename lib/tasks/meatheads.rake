
namespace :meatheads do

  desc "Initialize meatheads test data"
  task :init => [:users, :company, :services]
  task :destroy => [:services_destroy, :company_destroy, :users_destroy]
  
  task :users do
  
    puts "#{Time.now}: creating meatheads users"
    @max_plan       = Plan.find_by_name("Max") || Plan.first
  
    # create users
  
    if (@meathead = User.find_by_email("meathead@peanut.com") )
      puts "user: meathead@peanut.com already in db"
    else
      @meathead = User.create(:name => "Meathead Manager", :email => "meathead@peanut.com", :password => "peanut", :password_confirmation => "peanut")
      @meathead.register!
      @meathead.activate!
    end

    if (@wimpy = User.find_by_email("wimpy@peanut.com") )
      puts "user: wimpy@peanut.com already in db"
    else
      @wimpy = User.create(:name => "Wimpy Arms", :email => "wimpy@peanut.com", :password => "peanut", :password_confirmation => "peanut")
      @wimpy.register!
      @wimpy.activate!
    end

    if (@skinny = User.find_by_email("skinny@peanut.com") )
      puts "user: skinny@peanut.com already in db"
    else
      @skinny = User.create(:name => "Skinny Legs", :email => "skinny@peanut.com", :password => "peanut", :password_confirmation => "peanut")
      @skinny.register!
      @skinny.activate!
    end
  
  end
  
  task :users_destroy do
    if (@meathead = User.find_by_email("meathead@peanut.com") )
      puts "meatheads: destroying user id #{@meathead.id} email #{@meathead.email}"
      @meathead.destroy
    end
    if (@wimpy = User.find_by_email("wimpy@peanut.com") )
      puts "meatheads: destroying user id #{@wimpy.id} email #{@wimpy.email}"
      @wimpy.destroy
    end
    if (@skinny = User.find_by_email("skinny@peanut.com") )
      puts "meatheads: destroying user id #{@skinny.id} email #{@skinny.email}"
      @skinny.destroy
    end
  end
  
  task :company do
    @meatheads = Company.find_by_subdomain('meatheads')

    if @meatheads.blank?
      puts "#{Time.now}: creating meatheads company"
      @meatheads = Company.create(:name => "Meat Heads", :time_zone => "Central Time (US & Canada)")
    end

    if @meatheads.subscription.blank?
      # create subscription in 'active' state
      @subscription = @meatheads.create_subscription(:user => @meathead, :plan => @max_plan)
      @subscription.active!
    end

    # add manager roles
    @meathead.grant_role('company manager', @meatheads)

    # assign providers
    @meatheads.user_providers.push(@meathead) unless @meatheads.user_providers.include?(@meathead)
    @meatheads.user_providers.push(@wimpy) unless @meatheads.user_providers.include?(@wimpy)
    @meatheads.user_providers.push(@skinny) unless @meatheads.user_providers.include?(@skinny)
  end

  # Destroying the company will also destroy the services and providers
  task :company_destroy do
    if (@meatheads = Company.find_by_subdomain('meatheads'))
      puts "meatheads: : destroying company id #{@meatheads.id} name #{@meatheads.name}"
      @meatheads.destroy(:all => true)
    else
      puts "meatheads: didn't find company meatheads"
    end
  end
  
  task :services do
  
    puts "#{Time.now}: adding meathead services ..."
  
    # create services
    @training         = @meatheads.services.find_by_name("Personal Training") || @meatheads.services.create(:name => "Personal Training", :duration => 60, :mark_as => "work", :price => 20.00, :allow_custom_duration => true)

    puts "#{Time.now}: adding meatheads service providers ..."

    # add service providers
    @training.user_providers.push(@wimpy) unless @training.user_providers.include?(@wimpy)
    @training.user_providers.push(@skinny) unless @training.user_providers.include?(@skinny)

    puts "#{Time.now}: completed"
  end
  
  task :services_destroy do
    @meatheads = Company.find_by_subdomain('meatheads')
    if @meatheads && (@training = @meatheads.services.find_by_name("Personal Training"))
      puts "meatheads: destroying service id #{@training.id} name #{@training.name}"
      @training.destroy
    end
  end

end
