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
  
  desc "Populate providers for the specified company"
  task :providers, :company_id, :count do |t, args|
    # find specified company
    company   = Company.find_by_id(args.company_id.to_i) || Company.first
    
    count     = args.count.to_i 
    count     = @@count_default if count == 0 # default value
    
    
    puts "#{Time.now}: populating #{count} providers for company #{company.name}"
    
    added = 0
    count.times do |i|
      if !company.may_add_provider?
        puts "#{Time.now}: xxx reached company provider limit"
        break
      end
      
      # create random provider
      provider = User.create(:name => Faker::Name.name, :email => Faker::Internet.free_email, :password => 'secret', :password_confirmation => 'secret')
      
      # add provider to company
      company.has_providers.push(provider)
      provider.grant_role('provider', company)
      
      added += 1
    end

    puts "#{Time.now}: completed, added #{added} providers"
  end

  desc "Populate free time for the specified company"
  task :free, :company_id, :count do |t, args|
    # find specified company
    company   = Company.find_by_id(args.company_id.to_i) || Company.first

    count     = args.count.to_i 
    count     = @@count_default if count == 0 # default value

    puts "#{Time.now}: populating free time for company #{company.name}"
    
    # find all providers
    providers = company.providers
    day_range = Range.new(0, count)
    scheduled = 0
    
    providers.each do |provider|
      puts "#{Time.now}: *** adding free time for #{provider.name} for the next #{day_range.last} days"
      day_range.each do |i|
        # build random start and end times
        hour_start  = rand(16)
        hour_end    = hour_start + rand(3) + 5
        
        day         = Time.now.beginning_of_day + i.days
        start_at    = day + hour_start.hours
        end_at      = day + hour_end.hours
        
        begin
          puts "*** trying to schedule free time: #{start_at} to #{end_at}" 
          @appt = AppointmentScheduler.create_free_appointment(company, provider, company.free_service, :start_at => start_at, :end_at => end_at)
          scheduled += 1
        rescue Exception => e
          puts "xxx scheduling error: #{e.message}"
        end
      end
    end
    
    puts "#{Time.now}: completed, scheduled #{scheduled} free appointments"
  end

  desc "Populate work appointments for the specified company"
  task :work, :company_id, :count do |t, args|
    # find specified company
    company   = Company.find_by_id(args.company_id.to_i) || Company.first
    
    count     = args.count.to_i 
    count     = @@count_default if count == 0 # default value

    puts "#{Time.now}: populating appointments for company: #{company.name}"
    
    # track scheduled appointments
    scheduled = 0
    
    while scheduled < count and (!(free_appts = company.appointments.free).blank?)
      free_appts.each do |appt|
        provider = appt.provider
      
        # find a random service performed by the provider
        service = provider.services[rand(provider.services.count)]
      
        if service.blank?
          puts "#{Time.now}: provider #{provider.name} does not provide any services"
          next
        end

        puts "#{Time.now}: *** scheduling - provider: #{provider.name}, service: #{service.name}, starting_at: #{appt.start_at}"
            
        Appointment.transaction do
          # create a random customer
          customer = User.create(:name => Faker::Name.name, :email => Faker::Internet.free_email, :password => 'secret', :password_confirmation => 'secret')

          begin
            # schedule the work appointment
            work_appointment = AppointmentScheduler.create_work_appointment(company, provider, service, service.duration, customer, 
                                                                            :start_at => appt.start_at.to_s(:appt_schedule))
            scheduled += 1
          rescue Exception => e
            puts "*** #{e.message}"
            raise ActiveRecord::Rollback
          end
        end
          
        # check limit
        break if scheduled >= count
      end # company.apointments
    end # while
  
    puts "#{Time.now}: completed, scheduled #{scheduled} work appointments"
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
