class Meatheads < WalnutDemo
  
  def initialize
    @meatheads = @meathead = @biceps_bill = @toned_tina = @wimpy_arms = @skinny_legs = nil
  end

  def create_users
    # create users
    @meathead    = create_user("meathead@walnutcalendar.com", "Meat Head", "meathead")

    @biceps_bill = create_user("bicepsbill@walnutcalendar.com", "Biceps Bill", "bicepsbill")
    @toned_tina  = create_user("tonedtina@walnutcalendar.com", "Toned Tina", "tonedtina")

    @wimpy_arms  = create_user("wimpyarms@walnutcalendar.com", "Wimpy Arms", "wimpyarms")
    @skinny_legs = create_user("skinnylegs@walnutcalendar.com", "Skinny Legs", "skinnylegs")
    @pregnant_pam = create_user("pregnantpam@walnutcalendar.com", "Pregnant Pam", "pregnantpam")
  end
  
  def destroy_users
    destroy_user("meathead@walnutcalendar.com")
    destroy_user("bicepsbill@walnutcalendar.com")
    destroy_user("tonedtina@walnutcalendar.com")
    destroy_user("wimpyarms@walnutcalendar.com")
    destroy_user("skinnylegs@walnutcalendar.com")    
  end

  def initialize_company
    @meatheads = create_company(@meathead, "Meatheads", "meatheads", "Max", "Central Time (US & Canada)")

    @meatheads.slogan = SLOGAN
    @meatheads.description = DESCRIPTION
    meatheads_logo = File.new(File.join(File.dirname(__FILE__), "images", "weightlifting.png"), 'rb')
    @meatheads.logo = Logo.new
    @meatheads.logo.image = meatheads_logo
    @meatheads.save
  end
  
  def deinitialize_company
    destroy_company('meatheads')
  end
  
  def create_services
    create_service(@meatheads, "Personal Training", [@meathead, @biceps_bill, @toned_tina], 60, 60.00)
    create_service(@meatheads, "Men's strength training", [@biceps_bill], 60, 60.00)
    create_service(@meatheads, "Women's strength training", [@toned_tina], 60, 60.00)
    create_service(@meatheads, "Fitness for Pregnant Women", [@toned_tina], 60, 60.00)
    create_service(@meatheads, "Nutrition and Health Advice", [@meathead], 60, 80.00)
    create_service(@meatheads, "Fitness assessment", [@meathead], 60, 80.00)
  end
  
  def create_appointments
  end
  
  def destroy_appointments
  end
  
  SLOGAN = "Work it out with us!"

  DESCRIPTION = <<-END_DESCRIPTION
    <h3><strong>Meatheads</strong> offers very personal training services.</h3>
    <p>Our staff are extremely experienced with all your personal training needs. We have special programs for heart health, women's
        and men's muscle building, fitness for pregnant women and more. Our staff include:</p>
    <ul>
      <li><strong>Meat Head</strong>, focus on fitness, health and nutrition</li>
      <li><strong>Biceps Bill</strong>, focus on body building</li>
      <li><strong>Toned Tina</strong> who focuses particularly on women's training </li>
    </ul>
    <p>We offer personal training sessions at your convenience. Please check our schedule for availability.</p>
  END_DESCRIPTION

end

