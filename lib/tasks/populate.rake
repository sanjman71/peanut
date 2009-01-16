namespace :db do
  namespace :populate do
    
    require 'populator'
    require 'faker'
    
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
  end
end