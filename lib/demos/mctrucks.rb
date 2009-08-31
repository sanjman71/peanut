class Mctrucks < WalnutDemo
  
  def initialize
    @mctrucks = @mrtrucks = @moving_van = nil
  end

  def create_users
    # create users
    @mrtrucks = create_user("mrtrucks@walnutcalendar.com", "Mr Trucks", "peanut")
  end
  
  def destroy_users
    destroy_user("mrtrucks@walnutcalendar.com")
  end

  def create_resources
    @moving_van = create_resource(@mctrucks, "Moving Van")
  end
  
  def destroy_resources
    destroy_resource(@mctrucks, "Moving Van")
  end
  
  def initialize_company
    @mctrucks = create_company(@mrtrucks, "McTrucks", "mctrucks", "Max", "Central Time (US & Canada)")
  end
  
  # Destroying the company will also destroy the services and providers
  def deinitialize_company
    destroy_company('mctrucks')
  end
  
  def create_services
    @mctrucks.resource_providers.push(@moving_van) unless @mctrucks.user_providers.include?(@moving_van)
    create_service(@mctrucks, "Rental", [@moving_van], 60, 10.00)
  end
    
end
