namespace :appointments do
  
  namespace :recurrence do
    desc "Expand recurrences for the specified company"
    task :expand => :environment do
      company = Company.find_by_name(ENV["COMPANY"])
      
      if company.blank?
        puts "please specify a COMPANY"
        exit
      end

      puts "#{Time.now}: expanding recurrences for #{company.name}"
      Appointment.expand_all_recurrences(company)
      puts "#{Time.now}: completed"
    end
  end # recurrence

end # appointemnts