require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :peanut do
    
    namespace :rp do
      
      desc "Initialize roles and privileges"
      task :init  => [:companies, :roles_privs, :appointments, :invoices, :services]

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
      
    end
  end
end
