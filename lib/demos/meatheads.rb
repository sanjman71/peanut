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

    @meatheads.slogan = SLOGAN
    @meatheads.description = DESCRIPTION
    meatheads_logo = File.new(File.join(File.dirname(__FILE__), "images", "truck.png"), 'rb')
    @meatheads.logo = Logo.new
    @meatheads.logo.image = meatheads_logo
    @meatheads.save
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
  
  SLOGAN = "Work it out with us!"

  DESCRIPTION = <<-END_DESCRIPTION
    <p>Meatheads offers very special personal training services. Our staff are extremely </p>

    <ol>
       <li>a Van,a very good choice for those odd-jobs which require some extra capacity</li>
       <li>14 feet, useful for moving a 1-2 bedroom apartment</li>
       <li>17 feet, used to move a house</li>
    </ol>

    <p>We have a number of each type of truck, so there should be plenty of availability.</p>
  END_DESCRIPTION

end

