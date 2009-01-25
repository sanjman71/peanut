namespace :db do
  namespace :populate do
    
    require 'populator'
    require 'faker'
    require 'test/factories'
    
    @@count_default = 20
    
    desc "Populate products for the first company in the database"
    task :products, :count do |t, args|
      count   = args.count.to_i 
      count   = @@count_default if count == 0 # default value
      
      # find first company
      company = Company.first
      
      puts "#{Time.now}: populating #{count} products for company #{company.name}"
      
      Product.populate count do |product|
        product.company_id      = company.id
        product.name            = Populator.words(1..3).titleize
        product.price_in_cents  = [500, 1000, 1500, 2000, 2500]
        product.inventory       = 5..50
      end
      
    end
    
    desc "Populate people for the first company in the database"
    task :people, :count do |t, args|
      count   = args.count.to_i 
      count   = @@count_default if count == 0 # default value
      
      # find first company
      company = Company.first
      
      puts "#{Time.now}: populating #{count} people for company #{company.name}"
      
      # save people ids in collection so they can be added to company after populate is done
      people_ids = []
      Person.populate count do |person|
        person.name = Faker::Name.name
        people_ids.push(person.id)
      end

      # associate each person to a company
      people_ids.each do |id|
        person = Person.find_by_id(id)
        company.resources.push(person)
      end
    end
  
  
    desc "Populate invoices for the first company in the database"
    task :invoices, :count do |t, args|
      count     = args.count.to_i 
      count     = @@count_default if count == 0 # default value
      
      # find first company
      company   = Company.first
      
      # find all people that provide services
      people    = company.people.select { |p| !p.services.blank? }
      person    = people.first
      service   = person.services.first
      customer  = Customer.first || Factory(:customer)
      
      puts "*** #{people.collect(&:name).join(", ")}"

      puts "#{Time.now}: populating #{count} invoices for #{person.name} for company #{company.name}"
      
      count.downto(1) do |i|
        # create appointments, choose day randomly
        day_start   = Time.now.beginning_of_day - rand(30).days
        start_at    = day_start
        appointment = Appointment.create(:company => company, :resource => person, :service => service, :customer => customer, :start_at => start_at)
      
        puts "*** start time: #{appointment.start_at.to_s(:appt_date)}"
        
        # create invoice
        appointment.invoice = AppointmentInvoice.create
        
        # set random price 
        appointment.invoice.line_items.first.update_attribute(:price_in_cents, rand(10000))
        
        # mark appointment as checked out
        appointment.checkout!
        
        # increment start_at
        start_at = appointment.end_at
      end
    end
    
  end # populate
end # db