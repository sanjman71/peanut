namespace :db do
  namespace :populate do
    
    desc "Populate company products"
    task :products do
      require 'populator'
      require 'faker'
      
      # find first company
      company = Company.first
      
      Product.populate 50 do |product|
        product.company_id      = company.id
        product.name            = Populator.words(1..3).titleize
        product.price_in_cents  = [500, 1000, 1500, 2000, 2500]
        product.inventory       = 5..50
      end
      
    end
    
  end
end