class MarysSalonAndSpa < WalnutDemo
  
  def create_users
    # create users
    @marysnips = create_user("marysnips@walnutcalendar.com", "Mary Snips", "marysnips")
  end
  
  def destroy_users
    destroy_user("marysnips@walnutcalendar.com")
  end
  
  def initialize_company
    @marys_salon = initialize_company(@marysnips, "Mary's Salon and Spa", "maryssalon", "Max", "Central Time (US & Canada)")

    # assign providers
    @marys_salon.providers.push(@mary_snips) unless @marys_salon.providers.include?(@mary_snips)
  end
  
  # Destroying the company will also destroy the services and providers
  def deinitialize_company
    if (@noelrose = Company.find_by_subdomain('noelrose'))
      puts "noelrose: destroying company id #{@noelrose.id} name #{@noelrose.name}"
      @noelrose.destroy
    else
      puts "noelrose: didn't find noelrose"
    end
  end
    
  def create_services
  
    puts "#{Time.now}: adding noelrose services ..."

    # create noelrose services, products
    @mens_haircut     = @noelrose.services.find_by_name("Men's Haircut") || @noelrose.services.create(:name => "Men's Haircut", :duration => 30, :mark_as => "work", :price => 20.00)
    @womens_haircut   = @noelrose.services.find_by_name("Women's Haircut") || @noelrose.services.create(:name => "Women's Haircut", :duration => 60, :mark_as => "work", :price => 50.00)
    @color1           = @noelrose.services.find_by_name("Single Process Color") || @noelrose.services.create(:name => "Single Process Color", :duration => 120, :mark_as => "work", :price => 65.00)
    @color2           = @noelrose.services.find_by_name("Touch-Up Color") || @noelrose.services.create(:name => "Touch-Up Color", :duration => 120, :mark_as => "work", :price => 45.00)
    @color3           = @noelrose.services.find_by_name("Glossing") || @noelrose.services.create(:name => "Glossing", :duration => 120, :mark_as => "work", :price => 25.00)

    puts "#{Time.now}: adding noelrose products ..."
    @shampoo          = @noelrose.products.find_or_create_by_name(:name => "Shampoo", :inventory => 5, :price => 10.00)
    @conditioner      = @noelrose.products.find_or_create_by_name(:name => "Conditioner", :inventory => 5, :price => 15.00)
    @pomade           = @noelrose.products.find_or_create_by_name(:name => "Pomade", :inventory => 5, :price => 12.00)

    puts "#{Time.now}: completed"
  end

  def destroy_services
    @noelrose = Company.find_by_subdomain('noelrose')
    if @noelrose && (@mens_haircut = @noelrose.services.find_by_name("Men's Haircut"))
      puts "noelrose: destroying service id #{@mens_haircut.id} name #{@mens_haircut.name}"
      @mens_haircut.destroy
    else
      puts "noelrose: didn't find service Men's Haircut"
    end
    if @noelrose && (@womens_haircut = @noelrose.services.find_by_name("Women's Haircut"))
      puts "noelrose: destroying service id #{@womens_haircut.id} name #{@womens_haircut.name}"
      @womens_haircut.destroy
    else
      puts "noelrose: didn't find service Women's Haircut"
    end
    if @noelrose && (@color1 = @noelrose.services.find_by_name("Single Process Color"))
      puts "noelrose: destroying service id #{@color1.id} name #{@color1.name}"
      @color1.destroy
    else
      puts "noelrose: didn't find service Single Process Color"
    end
    if @noelrose && (@color2 = @noelrose.services.find_by_name("Touch-Up Color"))
      puts "noelrose: destroying service id #{@color2.id} name #{@color2.name}"
      @color2.destroy
    else
      puts "noelrose: didn't find service Touch-Up Color"
    end
    if @noelrose && (@color3 = @noelrose.services.find_by_name("Glossing"))
      puts "noelrose: destroying service id #{@color3.id} name #{@color3.name}"
      @color3.destroy
    else
      puts "noelrose: didn't find service Single Process Color"
    end
  end
  
  
end
