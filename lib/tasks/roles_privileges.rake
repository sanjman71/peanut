require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :rp do
  
  desc "Initialize roles and privileges"
  task :init  => [:companies, :roles_privs, :appointments, :calendars, :users, :invoices, :services, :customers, :products, :events]

  desc "Initialize company roles and privileges"
  # Avoid name clash with company data initialization by postfixing rp
  task :companies do
    
    puts "adding company roles & privileges"
    cm = Badges::Role.create(:name=>"company manager")
    p = Badges::Role.create(:name=>"provider")
    c = Badges::Role.create(:name=>"customer")

    cc = Badges::Privilege.create(:name=>"create companies")
    rc = Badges::Privilege.create(:name=>"read companies")
    uc = Badges::Privilege.create(:name=>"update companies")
    dc = Badges::Privilege.create(:name=>"delete companies")

    # Company manager can read & update company
    Badges::RolePrivilege.create(:role=>cm,:privilege=>rc)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>uc)

    # Providers can read company
    Badges::RolePrivilege.create(:role=>p,:privilege=>rc)
    
    # Customer has no privileges
  end
  
  desc "Initialize roles & privileges roles and privileges"
  task :roles_privs do

    puts "adding roles & privileges roles & privileges (!)"

    # Roles and privileges for managing roles and privileges
    # Initially only available to the admin
    Badges::Privilege.create(:name=>'create roles privileges')
    Badges::Privilege.create(:name=>'read roles privileges')
    Badges::Privilege.create(:name=>'update roles privileges')
    Badges::Privilege.create(:name=>'delete roles privileges')

  end
  
  desc "Initialize appointments roles and privileges"
  task :appointments do
    
    puts "adding appointments roles & privileges"

    cm = Badges::Role.find_by_name('company manager')
    p = Badges::Role.find_by_name('provider')

    # Appointments are broken into free, work and wait appointments
    # In general, the public can view free appointments and create work and wait appointments
    cwa = Badges::Privilege.create(:name=>"create work appointments")
    rwa = Badges::Privilege.create(:name=>"read work appointments")
    uwa = Badges::Privilege.create(:name=>"update work appointments")
    dwa = Badges::Privilege.create(:name=>"delete work appointments")

    cw2a = Badges::Privilege.create(:name=>"create wait appointments")
    rw2a = Badges::Privilege.create(:name=>"read wait appointments")
    uw2a = Badges::Privilege.create(:name=>"update wait appointments")
    dw2a = Badges::Privilege.create(:name=>"delete wait appointments")

    # Company manager can fully manage schedules
    Badges::RolePrivilege.create(:role=>cm,:privilege=>cwa)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>rwa)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>uwa)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>dwa)

    Badges::RolePrivilege.create(:role=>cm,:privilege=>cw2a)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>rw2a)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>uw2a)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>dw2a)

    # Providers can read schedules
    Badges::RolePrivilege.create(:role=>cm,:privilege=>cwa)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>cw2a)
    Badges::RolePrivilege.create(:role=>p,:privilege=>rwa)
    Badges::RolePrivilege.create(:role=>p,:privilege=>rw2a)
    
    # Authenticated users can create work and wait appointments
    auth = Badges::Role.find_by_name('authenticated')
    Badges::RolePrivilege.create(:role=>auth,:privilege=>cwa)
    Badges::RolePrivilege.create(:role=>auth,:privilege=>cw2a)
  end
  
  desc "Initialize calendars roles and privileges"
  task :calendars do
  
    puts "adding calendars roles & privileges"

    cm = Badges::Role.find_by_name('company manager')
    p = Badges::Role.find_by_name('provider')

    # Calendars
    rc = Badges::Privilege.create(:name=>"read calendars")
    uc = Badges::Privilege.create(:name=>"update calendars")

    # Company manager can fully manage calendars
    Badges::RolePrivilege.create(:role=>cm,:privilege=>rc)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>uc)

    # Providers can read calendars
    Badges::RolePrivilege.create(:role=>p,:privilege=>rc)
  end
  
  desc "Initialize user management roles & privileges"
  task :users do

    puts "adding user management roles & privileges"
    
    cm = Badges::Role.find_by_name('company manager')
    p = Badges::Role.find_by_name('provider')
    
    cu = Badges::Privilege.create(:name=>"create users")
    ru = Badges::Privilege.create(:name=>"read users")
    uu = Badges::Privilege.create(:name=>"update users")
    du = Badges::Privilege.create(:name=>"delete users")

    # Company manager can manage a company's users
    Badges::RolePrivilege.create(:role=>cm,:privilege=>ru)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>uu)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>du)

    # Providers can view users
    Badges::RolePrivilege.create(:role=>p,:privilege=>ru)
  end
  
  desc "Initialize invoices roles and privileges"
  task :invoices do
    
    puts "adding invoices roles & privileges"

    cm = Badges::Role.find_by_name('company manager')
    p = Badges::Role.find_by_name('provider')

    im = Badges::Role.create(:name => "invoice manager")

    # Invoices
    ci = Badges::Privilege.create(:name=>"create invoices")
    ri = Badges::Privilege.create(:name=>"read invoices")
    ui = Badges::Privilege.create(:name=>"update invoices")
    di = Badges::Privilege.create(:name=>"delete invoices")

    # Company manager can manage invoices
    Badges::RolePrivilege.create(:role=>cm,:privilege=>ci)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>ri)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>ui)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>di)

    # Invoice manager can manage invoices
    Badges::RolePrivilege.create(:role=>im,:privilege=>ci)
    Badges::RolePrivilege.create(:role=>im,:privilege=>ri)
    Badges::RolePrivilege.create(:role=>im,:privilege=>ui)
    Badges::RolePrivilege.create(:role=>im,:privilege=>di)
  end

  desc "Initialize services roles and privileges"
  task :services do 

    puts "adding services roles & privileges"

    cm = Badges::Role.find_by_name('company manager')
    p = Badges::Role.find_by_name('provider')

    # Services
    cs = Badges::Privilege.create(:name=>"create services")
    rs = Badges::Privilege.create(:name=>"read services")
    us = Badges::Privilege.create(:name=>"update services")
    ds = Badges::Privilege.create(:name=>"delete services")

    # Company manager can manage services
    Badges::RolePrivilege.create(:role=>cm,:privilege=>cs)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>rs)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>us)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>ds)

    # Providers can view services
    Badges::RolePrivilege.create(:role=>p,:privilege=>rs)
  end
  
  desc "Initialize customer management roles & privileges"
  task :customers do
    
    puts "adding customer management roles & privileges"
    
    cm = Badges::Role.find_by_name('company manager')
    ce = Badges::Role.find_by_name('provider')

    cc = Badges::Privilege.create(:name=>"create customers")
    rc = Badges::Privilege.create(:name=>"read customers")
    uc = Badges::Privilege.create(:name=>"update customers")
    dc = Badges::Privilege.create(:name=>"delete customers")

    # Company manager can manage a company's customers
    Badges::RolePrivilege.create(:role=>cm,:privilege=>rc)
    
    # TODO - add more privileges and roles here as appropriate

  end

  desc "Initialize products management roles & privileges"
  task :products do
    
    puts "adding products management roles & privileges"
    
    cm = Badges::Role.find_by_name('company manager')
    p = Badges::Role.find_by_name('provider')

    c = Badges::Privilege.create(:name=>"create products")
    r = Badges::Privilege.create(:name=>"read products")
    u = Badges::Privilege.create(:name=>"update products")
    d = Badges::Privilege.create(:name=>"delete products")

    # Company manager can manage products
    Badges::RolePrivilege.create(:role=>cm,:privilege=>c)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>r)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>u)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>d)

    # Provider can view products
    Badges::RolePrivilege.create(:role=>p,:privilege=>r)
  end
    
  desc "Initialize events management roles & privileges"
  task :events do
    
    puts "adding events management roles & privileges"
    
    cm = Badges::Role.find_by_name('company manager')
    p = Badges::Role.find_by_name('provider')

    c = Badges::Privilege.create(:name=>"create events")
    r = Badges::Privilege.create(:name=>"read events")
    u = Badges::Privilege.create(:name=>"update events")
    d = Badges::Privilege.create(:name=>"delete events")

    # Company manager can manage events
    Badges::RolePrivilege.create(:role=>cm,:privilege=>r)
    Badges::RolePrivilege.create(:role=>cm,:privilege=>u)

    # Providers can view events
    Badges::RolePrivilege.create(:role=>p,:privilege=>r)
  end

end
