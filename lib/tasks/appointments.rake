namespace :appointments do
  
  namespace :recurrence do
    desc "Expand recurrences for the specified company or ALL companies"
    task :expand => :environment do
      companies   = ENV["COMPANY"] ? Array(Company.find_by_name(ENV["COMPANY"])) :
                    (ENV["COMPANIES"].to_s.downcase == 'all' ? Company.with_subscriptions : [])

      if companies.blank?
        puts "please specify COMPANY or COMPANIES"
        exit
      end

      companies.each do |company|
        puts "#{Time.now}: expanding recurrences for #{company.name}"
        Appointment.expand_all_recurrences(company)
      end
      puts "#{Time.now}: completed"
    end
  end # recurrence

end # appointemnts