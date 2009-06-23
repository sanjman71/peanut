require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :rp do
  
  desc "Initialize roles and privileges"
  task :init  => [:companies, :roles_privs, :appointments, :calendars, :users, :invoices, :services, :customers, :resources, :products, :log_entries]

  desc "Initialize company roles and privileges"
  # Avoid name clash with company data initialization by postfixing rp
  task :companies do
    
    puts "adding company roles & privileges"
    m = Badges::Role.create(:name=>"manager")
    p = Badges::Role.create(:name=>"provider")
    c = Badges::Role.create(:name=>"customer")

    cc = Badges::Privilege.create(:name=>"create companies")
    rc = Badges::Privilege.create(:name=>"read companies")
    uc = Badges::Privilege.create(:name=>"update companies")
    dc = Badges::Privilege.create(:name=>"delete companies")

    # Managers can read & update company
    Badges::RolePrivilege.create(:role=>m,:privilege=>rc)
    Badges::RolePrivilege.create(:role=>m,:privilege=>uc)

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

    m = Badges::Role.find_by_name('manager')
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

    # Managers can fully manage schedules
    Badges::RolePrivilege.create(:role=>m,:privilege=>cwa)
    Badges::RolePrivilege.create(:role=>m,:privilege=>rwa)
    Badges::RolePrivilege.create(:role=>m,:privilege=>uwa)
    Badges::RolePrivilege.create(:role=>m,:privilege=>dwa)

    Badges::RolePrivilege.create(:role=>m,:privilege=>cw2a)
    Badges::RolePrivilege.create(:role=>m,:privilege=>rw2a)
    Badges::RolePrivilege.create(:role=>m,:privilege=>uw2a)
    Badges::RolePrivilege.create(:role=>m,:privilege=>dw2a)

    # Providers can read schedules
    Badges::RolePrivilege.create(:role=>m,:privilege=>cwa)
    Badges::RolePrivilege.create(:role=>m,:privilege=>cw2a)
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

    m = Badges::Role.find_by_name('manager')
    p = Badges::Role.find_by_name('provider')

    # Calendars
    rc = Badges::Privilege.create(:name=>"read calendars")
    uc = Badges::Privilege.create(:name=>"update calendars")

    # Managers can fully manage calendars
    Badges::RolePrivilege.create(:role=>m,:privilege=>rc)
    Badges::RolePrivilege.create(:role=>m,:privilege=>uc)

    # Providers can read calendars
    Badges::RolePrivilege.create(:role=>p,:privilege=>rc)
  end
  
  desc "Initialize user management roles & privileges"
  task :users do

    puts "adding user management roles & privileges"
    
    m = Badges::Role.find_by_name('manager')
    p = Badges::Role.find_by_name('provider')
    
    cu = Badges::Privilege.create(:name=>"create users")
    ru = Badges::Privilege.create(:name=>"read users")
    uu = Badges::Privilege.create(:name=>"update users")
    du = Badges::Privilege.create(:name=>"delete users")

    # Managers can manage a company's users
    Badges::RolePrivilege.create(:role=>m,:privilege=>ru)
    Badges::RolePrivilege.create(:role=>m,:privilege=>uu)
    Badges::RolePrivilege.create(:role=>m,:privilege=>du)

    # Providers can view users
    Badges::RolePrivilege.create(:role=>p,:privilege=>ru)
  end
  
  desc "Initialize invoices roles and privileges"
  task :invoices do
    
    puts "adding invoices roles & privileges"

    m = Badges::Role.find_by_name('manager')
    p = Badges::Role.find_by_name('provider')

    im = Badges::Role.create(:name => "invoice manager")

    # Invoices
    ci = Badges::Privilege.create(:name=>"create invoices")
    ri = Badges::Privilege.create(:name=>"read invoices")
    ui = Badges::Privilege.create(:name=>"update invoices")
    di = Badges::Privilege.create(:name=>"delete invoices")

    # Managers can manage invoices
    Badges::RolePrivilege.create(:role=>m,:privilege=>ci)
    Badges::RolePrivilege.create(:role=>m,:privilege=>ri)
    Badges::RolePrivilege.create(:role=>m,:privilege=>ui)
    Badges::RolePrivilege.create(:role=>m,:privilege=>di)

    # Invoice manager can manage invoices
    Badges::RolePrivilege.create(:role=>im,:privilege=>ci)
    Badges::RolePrivilege.create(:role=>im,:privilege=>ri)
    Badges::RolePrivilege.create(:role=>im,:privilege=>ui)
    Badges::RolePrivilege.create(:role=>im,:privilege=>di)
  end

  desc "Initialize services roles and privileges"
  task :services do 

    puts "adding services roles & privileges"

    m = Badges::Role.find_by_name('manager')
    p = Badges::Role.find_by_name('provider')

    # Services
    cs = Badges::Privilege.create(:name=>"create services")
    rs = Badges::Privilege.create(:name=>"read services")
    us = Badges::Privilege.create(:name=>"update services")
    ds = Badges::Privilege.create(:name=>"delete services")

    # Managers can manage services
    Badges::RolePrivilege.create(:role=>m,:privilege=>cs)
    Badges::RolePrivilege.create(:role=>m,:privilege=>rs)
    Badges::RolePrivilege.create(:role=>m,:privilege=>us)
    Badges::RolePrivilege.create(:role=>m,:privilege=>ds)

    # Providers can view services
    Badges::RolePrivilege.create(:role=>p,:privilege=>rs)
  end
  
  desc "Initialize customer management roles & privileges"
  task :customers do
    
    puts "adding customer management roles & privileges"
    
    m = Badges::Role.find_by_name('manager')
    p = Badges::Role.find_by_name('provider')

    cc = Badges::Privilege.create(:name=>"create customers")
    rc = Badges::Privilege.create(:name=>"read customers")
    uc = Badges::Privilege.create(:name=>"update customers")
    dc = Badges::Privilege.create(:name=>"delete customers")

    # Managers can manage a company's customers
    Badges::RolePrivilege.create(:role=>m,:privilege=>rc)
  end

  desc "Initialize resources management roles & privileges"
  task :resources do
    puts "adding resources management roles & privileges"
    
    m = Badges::Role.find_by_name('manager')
    p = Badges::Role.find_by_name('provider')

    cr = Badges::Privilege.create(:name=>"create resources")
    rr = Badges::Privilege.create(:name=>"read resources")
    ur = Badges::Privilege.create(:name=>"update resources")
    dr = Badges::Privilege.create(:name=>"delete resources")

    # Managers can manage resources
    Badges::RolePrivilege.create(:role=>m,:privilege=>cr)
    Badges::RolePrivilege.create(:role=>m,:privilege=>ur)
    Badges::RolePrivilege.create(:role=>m,:privilege=>dr)
  end
  
  desc "Initialize products management roles & privileges"
  task :products do
    
    puts "adding products management roles & privileges"
    
    m = Badges::Role.find_by_name('manager')
    p = Badges::Role.find_by_name('provider')

    c = Badges::Privilege.create(:name=>"create products")
    r = Badges::Privilege.create(:name=>"read products")
    u = Badges::Privilege.create(:name=>"update products")
    d = Badges::Privilege.create(:name=>"delete products")

    # Managers can manage products
    Badges::RolePrivilege.create(:role=>m,:privilege=>c)
    Badges::RolePrivilege.create(:role=>m,:privilege=>r)
    Badges::RolePrivilege.create(:role=>m,:privilege=>u)
    Badges::RolePrivilege.create(:role=>m,:privilege=>d)

    # Provider can view products
    Badges::RolePrivilege.create(:role=>p,:privilege=>r)
  end
    
  desc "Initialize log_entries management roles & privileges"
  task :log_entries do
    
    puts "adding log_entries management roles & privileges"
    
    m = Badges::Role.find_by_name('manager')
    p = Badges::Role.find_by_name('provider')

    c = Badges::Privilege.create(:name=>"create log_entries")
    r = Badges::Privilege.create(:name=>"read log_entries")
    u = Badges::Privilege.create(:name=>"update log_entries")
    d = Badges::Privilege.create(:name=>"delete log_entries")

    # Managers can manage log_entries
    Badges::RolePrivilege.create(:role=>m,:privilege=>r)
    Badges::RolePrivilege.create(:role=>m,:privilege=>u)

    # Providers can view log_entries
    Badges::RolePrivilege.create(:role=>p,:privilege=>r)
  end

end
