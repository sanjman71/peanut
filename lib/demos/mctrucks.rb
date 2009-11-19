class Mctrucks < WalnutDemo
  
  def initialize
    @mctrucks = @mrtrucks = @moving_van = nil
  end

  def create_users
    # create users
    @mrtrucks = create_user("mrtrucks@walnutcalendar.com", "Mr Trucks", "mrtrucks")
  end
  
  def destroy_users
    destroy_user("mrtrucks@walnutcalendar.com")
  end

  def create_resources
    @moving_van  = create_resource('mctrucks', "Moving Van")
    @small_truck = create_resource('mctrucks', "14 foot truck")
    @large_truck = create_resource('mctrucks', "17 foot truck")
  end
  
  def destroy_resources
    destroy_resource('mctrucks', "Moving Van")
    destroy_resource('mctrucks', "14 foot truck")
    destroy_resource('mctrucks', "17 foot truck")
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
    @van_service         = create_service(@mctrucks, "Van rental (hourly)", [@moving_van], 60.minutes, 10.00)
    @small_truck_service = create_service(@mctrucks, "14 foot truck rental (hourly)", [@small_truck], 60.minutes, 15.00)
    @large_truck_service = create_service(@mctrucks, "17 foot truck rental (hourly)", [@large_truck], 60.minutes, 20.00)
  end

  def create_appointments
    # The vans are available all day every day, including weekends. We have 3 of them.
    create_weekly_free_appt(@mctrucks, @moving_van, 8.hours, 18.hours, :days => "MO,TU,WE,TH,FR,SA,SU", :capacity => 3)
    # The small trucks are available all day every day, including weekends. We have 4 of them.
    create_weekly_free_appt(@mctrucks, @small_truck, 8.hours, 18.hours, :days => "MO,TU,WE,TH,FR,SA,SU", :capacity => 4)
    # The large trucks are available all day every day, including weekends. We have 2 of them.
    create_weekly_free_appt(@mctrucks, @large_truck, 8.hours, 18.hours, :days => "MO,TU,WE,TH,FR,SA,SU", :capacity => 2)
  end
  
  SLOGAN = "We'll haul you away!"

  DESCRIPTION = <<-END_DESCRIPTION
    <p>McTrucks rents vans and trucks by the hour. We have 3 different types of vehicle to choose from:</p>

    <ol>
       <li><strong>A van</strong> - a very good choice for those odd-jobs which require more capacity than your family car</li>
       <li><strong>A 14 foot gas truck</strong> - useful for moving a 1-2 bedroom apartment full of furniture</li>
       <li><strong>A 17 foot diesel truck</strong> - used to move a house full of furniture</li>
    </ol>

    <p>We have a number of each type of truck, so there should be plenty of availability.</p>
  END_DESCRIPTION

end
