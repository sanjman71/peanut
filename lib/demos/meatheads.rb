class Meatheads < WalnutDemo
  
  def initialize
    @meatheads = @meathead = @biceps_bill = @toned_tina = @wimpy_arms = @skinny_legs = nil
  end

  def create_users
    # create users
    @meathead    = create_user("meathead@walnutcalendar.com", "Meathead Manager", "meathead")

    @biceps_bill = create_user("bicepsbill@walnutcalendar.com", "Biceps Bill", "bicepsbill")
    @toned_tina  = create_user("tonedtina@walnutcalendar.com", "Toned Tina", "tonedtina")

    @wimpy_arms  = create_user("wimpyarms@walnutcalendar.com", "Wimpy Arms", "wimpyarms")
    @skinny_legs = create_user("skinnylegs@walnutcalendar.com", "Skinny Legs", "skinnylegs")
  end
  
  def destroy_users
    destroy_user("meathead@walnutcalendar.com")
    destroy_user("bicepsbill@walnutcalendar.com")
    destroy_user("tonedtina@walnutcalendar.com")
    destroy_user("wimpyarms@walnutcalendar.com")
    destroy_user("skinnylegs@walnutcalendar.com")    
  end

  def initialize_company
    @meatheads = create_company(@meathead, "Meat Heads", "meatheads", "Max", "Central Time (US & Canada)")
  end
  
  def deinitialize_company
    destroy_company('meatheads')
  end
  
  def create_services
    create_service(@meatheads, "Personal Training", [@biceps_bill, @toned_tina], 60, 20.00)
  end
  
  def create_appointments
  end
  
  def destroy_appointments
  end
  
end

