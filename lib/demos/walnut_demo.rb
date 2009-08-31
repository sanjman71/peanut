class WalnutDemo
  
  def create
    create_users
    initialize_company
    create_resources
    create_services
    create_appointments
  end
  
  def destroy
    deinitialize_company # Will also destroy services, appointments, capacity slots, subscription and all join tables
    destroy_resources
    destroy_users
  end
  
  def create_users
  end
  
  def destroy_users
  end
  
  def initialize_company
  end
  
  def deinitialize_company
  end
  
  def create_resources
  end
  
  def destroy_resources
  end
  
  def create_services
  end
  
  def create_appointments
  end
  
  protected
  
  # Useful Regex for search and replace:
  # ^.*find_by_email\((["a-zA-Z@\.]*).*\n.*\n.*\n.*:name => (["a-zA-Z@\.\ ]*),.*\n.*:password => (["a-zA-Z@\.]*).*\n.*\n.*\n.*
  # create_user($1, $2, $3)
  def create_user(user_email, user_name, user_pwd)
    puts "create user: #{user_name}"
    if (user = User.find_by_email(user_email))
      puts "create user: #{user_email} already in db"
    else
      user = User.create(:name => user_name, :email => user_email, :password => user_pwd, :password_confirmation => user_pwd)
      user.register!
      user.activate!
    end
    puts "finished creating user: #{user_name}"
    user
  end
  
  def destroy_user(user_email)
    if (user = User.find_by_email(user_email) )
      puts "destroy_user: destroying user id #{user.id} email #{user.email}"
      user.destroy
    else
      puts "destroy_user: didn't find user #{user_email}"
    end
  end
  
  def create_resource(company, name)
    puts "#{company.name}: create resource: #{name}"
    if company.blank?
      company
    elsif resource = company.resource_providers.find_by_name(name)
      puts "#{company.name}: create_resource: #{name} already in db"
    else
      # create resource
      resource = Resource.create(:name => name)
    end
    puts "#{company.name}: finished creating resource: #{name}"
    resource
  end
  
  def destroy_resource(company, name)
    if company && (resource = company.resource_providers.find_by_name(name))
      puts "#{company.name}: destroying resource id #{resource.id} name #{name}"
      resource.destroy
    else
      puts "#{company.name}: destroy_resource: didn't find resource #{name}"
    end
  end
  
  def create_company(owner, name, subdomain, plan, timezone)
    puts "#{name}: initializing company"
    company = Company.find_by_subdomain(subdomain)
    if company.blank?
      # create subscriptions
      plan       = Plan.find_by_name(plan) || Plan.first
      sub        = Subscription.create(:user => owner, :plan => plan)
  
      puts "#{Time.now}: creating company #{name}"
      # create test companies
      company = Company.create(:name => name, :time_zone => timezone, :subscription => sub)
    end
    puts "#{name}: granting #{owner.name} company manager role"
    owner.grant_role('company manager', company)
    puts "#{name}: finished initializing company"
    company
  end
  
  def destroy_company(subdomain)
    puts "destroy_company: #{subdomain}"
    if (company = Company.find_by_subdomain(subdomain))
      puts "destroy_company: destroying company id #{company.id} name #{company.name}"
      company.destroy
    else
      puts "destroy_company: didn't find company #{subdomain}"
    end
    puts "destroy_company: finished destroying #{subdomain}"
  end
  
  def create_service(company, svc_name, users_or_resources, duration, price)
    # create services
    puts "#{company.name}: creating service #{svc_name}"
    svc = company.services.find_by_name(svc_name) || company.services.create(:name => svc_name, :duration => duration, :mark_as => "work", :price => price)

    # add service providers
    users_or_resources.each do |ur|
      if ur.class == User
        svc.user_providers.push(ur) unless svc.user_providers.include?(ur)
        puts "#{company.name}: Adding user provider #{ur.name}"
      elsif ur.class == Resource
        svc.resource_providers.push(ur) unless svc.providers.include?(ur)
        puts "#{company.name}: Adding resource provider #{ur.name}"
      end
    end
    puts "#{company.name}: finished creating service #{svc_name}"
  end
  
end
