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
    @moving_van = create_resource('mctrucks', "Moving Van")
  end
  
  def destroy_resources
    destroy_resource('mctrucks', "Moving Van")
  end
  
  def initialize_company
    @mctrucks = create_company(@mrtrucks, "McTrucks", "mctrucks", "Max", "Central Time (US & Canada)")
    @mctrucks.slogan = SLOGAN
    @mctrucks.description = DESCRIPTION
    truck_logo = File.new(File.join(File.dirname(__FILE__), "images", "truck.png"), 'rb')
    @mctrucks.logo = Logo.new
    @mctrucks.logo.image = truck_logo
    @mctrucks.save
  end
  
  # Destroying the company will also destroy the services and providers
  def deinitialize_company
    destroy_company('mctrucks')
  end
  
  def create_services
    create_service(@mctrucks, "Rental", [@moving_van], 60, 10.00)
  end

  SLOGAN = "We'll haul you away"

  DESCRIPTION = <<-END_DESCRIPTION
    <p>McTrucks rents different kinds of trucks. We have 3 different types of truck</p>

    <ol>
       <li>a Van,a very good choice for those odd-jobs which require some extra capacity</li>
       <li>14 feet, useful for moving a 1-2 bedroom apartment</li>
       <li>17 feet, used to move a house</li>
    </ol>

    <p>We have a number of each type of truck, so there should be plenty of availability.</p>
  END_DESCRIPTION

end
