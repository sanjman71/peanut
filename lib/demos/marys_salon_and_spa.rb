class MarysSalonAndSpa < WalnutDemo
  
  def initialize
    @marys_salon = @mary_snips = @johnny_shears = nil
  end

  def create_users
    # create users
    @mary_snips    = create_user("marysnips@walnutcalendar.com", "Mary Snips", "marysnips")
    @johnny_shears = create_user("johnnyshears@walnutcalendar.com", "Johnny Shears", "johnnyshears")
  end
  
  def destroy_users
    destroy_user("marysnips@walnutcalendar.com")
    destroy_user("johnnyshears@walnutcalendar.com")
  end
  
  def initialize_company
    @marys_salon = create_company(@mary_snips, "Mary's Salon and Spa", "maryssalon", "Max", "Central Time (US & Canada)")
  end
  
  # Destroying the company will also destroy the services and providers
  def deinitialize_company
    destroy_company('maryssalon')
  end
    
  def create_services
    # create maryssalon services, products
    @mens_haircut   = create_service(@marys_salon, "Men's Haircut", [@johnny_shears], 30.minutes, 20.00)
    @womens_haircut = create_service(@marys_salon, "Women's Haircut", [@mary_snips, @johnny_shears], 60.minutes, 50.00)
    @sp_color       = create_service(@marys_salon, "Single Process Color", [@mary_snips], 120.minutes, 65.00)
    @tu_color       = create_service(@marys_salon, "Touch-Up Color", [@mary_snips], 120.minutes, 45.00)
    @glossing       = create_service(@marys_salon, "Glossing", [@mary_snips], 120.minutes, 25.00)

    # puts "#{Time.now}: adding maryssalon products ..."
    # @shampoo          = @marys_salon.products.find_or_create_by_name(:name => "Shampoo", :inventory => 5, :price => 10.00)
    # @conditioner      = @marys_salon.products.find_or_create_by_name(:name => "Conditioner", :inventory => 5, :price => 15.00)
    # @pomade           = @marys_salon.products.find_or_create_by_name(:name => "Pomade", :inventory => 5, :price => 12.00)
  end
  
  def create_appointments
    # Mary and Johnny work every workday
    create_weekly_free_appt(@marys_salon, @mary_snips, 9.hours, 14.hours)
    create_weekly_free_appt(@marys_salon, @johnny_shears, 13.hours, 18.hours)
  end
  
end
