namespace :export do

  desc "Export customer list"
  task :customers => :environment do
    company_name = ENV["COMPANY"].to_s
    
    if company_name.blank?
      puts "missing COMPANY"
      exit
    end

    company = Company.find_by_name!(company_name)
    file    = "#{company.subdomain}.customers.csv"

    CSV.open(file, "w") do |csv|
      # csv << ["Name", "Email", "Phone"]
      
      company.customers.each do |customer|
        name  = customer.name
        email = customer.try(:primary_email_address).try(:address)
        phone = customer.try(:primary_phone_number).try(:address)
        
        csv << [name, email, phone]
      end
    end
  end
  
end
