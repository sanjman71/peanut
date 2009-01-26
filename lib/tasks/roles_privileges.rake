require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :peanut do
    
    namespace :rp do
      
      desc "Initialize roles and privileges"
      task :init  => [:companies, :roles_privs, :appointments, :invoices, :services, :users, :customers, :people, :products, :waitlist]

      desc "Initialize company roles and privileges"
      # Avoid name clash with company data initialization by postfixing rp
      task :companies do
        
        puts "adding company roles & privileges"
        cm = Badges::Role.create(:name=>"company manager")
        ce = Badges::Role.create(:name=>"company employee")

        cc = Badges::Privilege.create(:name=>"create companies")
        rc = Badges::Privilege.create(:name=>"read companies")
        uc = Badges::Privilege.create(:name=>"update companies")
        dc = Badges::Privilege.create(:name=>"delete companies")

        # Company manager can read & update company
        Badges::RolePrivilege.create(:role=>cm,:privilege=>rc)
        Badges::RolePrivilege.create(:role=>cm,:privilege=>uc)

        # Company employee can read company                   
        Badges::RolePrivilege.create(:role=>ce,:privilege=>rc)

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
        ce = Badges::Role.find_by_name('company employee')

        # Appointments are broken into free and work appointments
        # In general, the public can view free appointments and create work appointments
        cfa = Badges::Privilege.create(:name=>"create free appointments")
        rwa = Badges::Privilege.create(:name=>"read free appointments")
        dfa = Badges::Privilege.create(:name=>"delete free appointments")

        cfa = Badges::Privilege.create(:name=>"create work appointments")
        rwa = Badges::Privilege.create(:name=>"read work appointments")
        dwa = Badges::Privilege.create(:name=>"delete work appointments")

        # Company manager can fully manage schedule
        Badges::RolePrivilege.create(:role=>cm,:privilege=>cfa)
        Badges::RolePrivilege.create(:role=>cm,:privilege=>rwa)
        Badges::RolePrivilege.create(:role=>cm,:privilege=>dfa)
        Badges::RolePrivilege.create(:role=>cm,:privilege=>dwa)

        # Company employee can read schedule
        Badges::RolePrivilege.create(:role=>ce,:privilege=>rwa)

      end
      
      desc "Initialize invoices roles and privileges"
      task :invoices do
        
        puts "adding invoices roles & privileges"

        cm = Badges::Role.find_by_name('company manager')
        ce = Badges::Role.find_by_name('company employee')

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
        ce = Badges::Role.find_by_name('company employee')

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

        # Company employee can view services
        Badges::RolePrivilege.create(:role=>ce,:privilege=>rs)

      end
      
      desc "Initialize user management roles & privileges"
      task :users do

        puts "adding user management roles & privileges"
        
        cm = Badges::Role.find_by_name('company manager')
        ce = Badges::Role.find_by_name('company employee')
        
        cu = Badges::Privilege.create(:name=>"create users")
        ru = Badges::Privilege.create(:name=>"read users")
        uu = Badges::Privilege.create(:name=>"update users")
        du = Badges::Privilege.create(:name=>"delete users")

        # Company manager can manage a company's users
        Badges::RolePrivilege.create(:role=>cm,:privilege=>ru)
        Badges::RolePrivilege.create(:role=>cm,:privilege=>uu)

        # Company employee can view services
        Badges::RolePrivilege.create(:role=>ce,:privilege=>ru)

      end
      
      desc "Initialize customer management roles & privileges"
      task :customers do
        
        puts "adding customer management roles & privileges"
        
        cm = Badges::Role.find_by_name('company manager')
        ce = Badges::Role.find_by_name('company employee')

        cc = Badges::Privilege.create(:name=>"create customers")
        rc = Badges::Privilege.create(:name=>"read customers")
        uc = Badges::Privilege.create(:name=>"update customers")
        dc = Badges::Privilege.create(:name=>"delete customers")

        # Company manager can manage a company's customers
        Badges::RolePrivilege.create(:role=>cm,:privilege=>rc)
        
        # TODO - add more privileges and roles here as appropriate

      end

      desc "Initialize people management roles & privileges"
      task :people do
        
        puts "adding people management roles & privileges"
        
        cm = Badges::Role.find_by_name('company manager')
        ce = Badges::Role.find_by_name('company employee')

        c = Badges::Privilege.create(:name=>"create people")
        r = Badges::Privilege.create(:name=>"read people")
        u = Badges::Privilege.create(:name=>"update people")
        d = Badges::Privilege.create(:name=>"delete people")

        # Company manager can manage a company's people
        Badges::RolePrivilege.create(:role=>cm,:privilege=>r)

        # TODO - add more privileges and roles here as appropriate

      end
      
      desc "Initialize products management roles & privileges"
      task :products do
        
        puts "adding products management roles & privileges"
        
        cm = Badges::Role.find_by_name('company manager')
        ce = Badges::Role.find_by_name('company employee')

        c = Badges::Privilege.create(:name=>"create products")
        r = Badges::Privilege.create(:name=>"read products")
        u = Badges::Privilege.create(:name=>"update products")
        d = Badges::Privilege.create(:name=>"delete products")

        # Company manager can manage a company's products
        Badges::RolePrivilege.create(:role=>cm,:privilege=>r)

        # TODO - add more privileges and roles here as appropriate

      end
      
      desc "Initialize waitlist management roles & privileges"
      task :waitlist do
        
        puts "adding waitlist management roles & privileges"
        
        cm = Badges::Role.find_by_name('company manager')
        ce = Badges::Role.find_by_name('company employee')

        c = Badges::Privilege.create(:name=>"create waitlist")
        r = Badges::Privilege.create(:name=>"read waitlist")
        u = Badges::Privilege.create(:name=>"update waitlist")
        d = Badges::Privilege.create(:name=>"delete waitlist")

        # Company manager can manage a company's waitlist
        Badges::RolePrivilege.create(:role=>cm,:privilege=>r)

        # TODO - add more privileges and roles here as appropriate

      end
      
    end
  end
end
