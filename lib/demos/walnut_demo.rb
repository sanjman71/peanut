class WalnutDemo
  
  def create
    create_users
    initialize_company
    create_resources
    create_services
    create_appointments
  end
  
  def destroy
    destroy_resources
    deinitialize_company # Will also destroy services, appointments, capacity slots, subscription and all join tables
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
    puts "create_user: #{user_name}"
    if (user = User.find_by_email(user_email))
      puts "create_user: #{user_email} already in db"
    else
      user = User.create(:name => user_name, :email => user_email, :password => user_pwd, :password_confirmation => user_pwd)
      user.register!
      user.activate!
    end
    puts "create_user: finished creating user #{user_name}"
    user
  end
  
  def destroy_user(user_email)
    puts "destroy_user: #{user_email}"
    if (user = User.find_by_email(user_email) )
      puts "destroy_user: destroying user id #{user.id} email #{user.email}"
      user.destroy
    else
      puts "destroy_user: didn't find user #{user_email}"
    end
    puts "destroy_user: finished destroying #{user_email}"
  end
  
  def create_resource(subdomain, name)
    puts "create_resource: #{name} for #{subdomain}"
    company = Company.find_by_subdomain(subdomain)
    if company.blank?
      company
    elsif resource = company.resource_providers.find_by_name(name)
      puts "create_resource: #{name} already in db"
    else
      # create resource
      resource = Resource.create(:name => name)
    end
    puts "create_resource: finished creating resource: #{name} for #{company.name}"
    resource
  end
  
  def destroy_resource(subdomain, name)
    puts "destroy_resource: #{name} for #{subdomain}"
    company = Company.find_by_subdomain(subdomain)
    resource = company.resource_providers.find_by_name(name) unless company.blank?
    if resource
      puts "destroy_resource: resource id #{resource.id} name #{name} for #{company.name}"
      resource.destroy
    else
      puts "destroy_resource: didn't find resource #{name} for #{subdomain}"
    end
    puts "destroy_resource: finished destroying #{name} for #{subdomain}"
  end
  
  def create_company(owner, name, subdomain, plan = "Max", timezone = "Central Time (US & Canada)")
    puts "create_company: #{name}"
    company = Company.find_by_subdomain(subdomain)
    if company.blank?
      puts "create_company: creating company #{name}"
      company = Company.create(:name => name, :time_zone => timezone, :subdomain => subdomain)
    end

    if company.subscription.blank?
      puts "create_company: creating subscription for #{name}"
      # create subscription in 'active' state
      plan = Plan.find_by_name(plan) || Plan.first
      sub  = company.create_subscription(:user => owner, :plan => plan)
      sub.active!
    end

    puts "create_company: granting #{owner.name} company manager role on #{name}"
    owner.grant_role('company manager', company)

    puts "create_company: finished creating company #{name}"
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
    puts "create_service: #{svc_name} for #{company.name}"
    svc = company.services.find_by_name(svc_name) || company.services.create(:name => svc_name, :duration => duration, :mark_as => "work", :price => price)

    # add service providers
    users_or_resources.each do |ur|
      if ur.class == User
        company.user_providers.push(ur) unless company.user_providers.include?(ur)
        svc.user_providers.push(ur) unless svc.user_providers.include?(ur)
        puts "create_service: Adding user provider #{ur.name} to #{company.name} for service #{svc_name}"
      elsif ur.class == Resource
        company.resource_providers.push(ur) unless company.resource_providers.include?(ur)
        svc.resource_providers.push(ur) unless svc.providers.include?(ur)
        puts "create_service: Adding resource provider #{ur.name} to #{company.name} for service #{svc_name}"
      end
    end
    puts "create_service: finished creating service #{svc_name} for #{company.name}"
  end
  
end
