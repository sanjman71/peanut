module BadgesInit
  
  def self.remove_all
    Badges::Privilege.all.each do |p|
      p.destroy
    end
    
    Badges::Role.all.each do |r|
      r.destroy
    end
  end
  
  def self.roles_privileges
    user  = Badges::Role.find_by_name(Badges::Config.default_user_role.to_s) || Badges::Role.create(:name=>Badges::Config.default_user_role.to_s)
    admin = Badges::Role.find_by_name(Badges::Config.default_admin_role.to_s) || Badges::Role.create(:name=>Badges::Config.default_admin_role.to_s)
    
    cm    = Badges::Role.find_by_name('company manager') || Badges::Role.create(:name=>"company manager")
    cp    = Badges::Role.find_by_name('company provider') || Badges::Role.create(:name=>"company provider")
    cc    = Badges::Role.find_by_name('company customer') || Badges::Role.create(:name=>"company customer")
    cs    = Badges::Role.find_by_name('company staff') || Badges::Role.create(:name=>"company staff")
    um    = Badges::Role.find_by_name('user manager') || Badges::Role.create(:name=>"user manager")
    am    = Badges::Role.find_by_name('appointment manager') || Badges::Role.create(:name=>"appointment manager")
    sm    = Badges::Role.find_by_name('site manager') || Badges::Role.create(:name=>"site manager")

    site(sm)
    companies(cm, cp, cc, cs, um)
    users(cm, cp, um)
    resources(cm, cp, um)
    calendars(cm, cp, um)
    services(cm, cp, um)
    appointments(cm, am)
  end

  def self.site(sm)
    # site privileges
    ms = Badges::Privilege.find_or_create_by_name(:name=>"manage site")
    mr = Badges::Privilege.find_or_create_by_name(:name=>"manage roles privileges")
    dr = Badges::Privilege.find_or_create_by_name(:name=>"delete roles privileges")

    # site managers can manage the site and roles & privileges
    Badges::RolePrivilege.create(:role=>sm, :privilege=>ms)
    Badges::RolePrivilege.create(:role=>sm, :privilege=>mr)
    
    # only admins can delete roles & privileges
  end
  
  def self.companies(cm, cp, cc, cs, um)
    # company privileges
    rc = Badges::Privilege.find_or_create_by_name(:name=>"read companies")
    uc = Badges::Privilege.find_or_create_by_name(:name=>"update companies")
    dc = Badges::Privilege.find_or_create_by_name(:name=>"delete companies")

    # company managers can manage the company
    Badges::RolePrivilege.create(:role=>cm, :privilege=>uc)
    
    # All roles can read companies. This is used to prevent public access of private companies
    Badges::RolePrivilege.create(:role=>cm, :privilege=>rc)
    Badges::RolePrivilege.create(:role=>cp, :privilege=>rc)
    Badges::RolePrivilege.create(:role=>cc, :privilege=>rc)
    Badges::RolePrivilege.create(:role=>cs, :privilege=>rc)
    
    # Only admin can delete a company
  end
  
  def self.users(cm, cp, um)
    # user privileges
    cu = Badges::Privilege.find_or_create_by_name(:name=>"create users")
    ru = Badges::Privilege.find_or_create_by_name(:name=>"read users")
    uu = Badges::Privilege.find_or_create_by_name(:name=>"update users")
    du = Badges::Privilege.find_or_create_by_name(:name=>"delete users")

    # company managers can manage users
    Badges::RolePrivilege.create(:role=>cm, :privilege=>cu)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>ru)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>uu)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>du)

    # company providers can read users
    Badges::RolePrivilege.create(:role=>cp, :privilege=>ru)

    # user managers can read, update, and delete users
    Badges::RolePrivilege.create(:role=>um, :privilege=>ru)
    Badges::RolePrivilege.create(:role=>um, :privilege=>uu)
    Badges::RolePrivilege.create(:role=>um, :privilege=>du)
  end

  def self.resources(cm, cp, um)
    # resource privileges
    cr = Badges::Privilege.find_or_create_by_name(:name=>"create resources")
    rr = Badges::Privilege.find_or_create_by_name(:name=>"read resources")
    ur = Badges::Privilege.find_or_create_by_name(:name=>"update resources")
    dr = Badges::Privilege.find_or_create_by_name(:name=>"delete resources")

    # company managers can manage resources
    Badges::RolePrivilege.create(:role=>cm, :privilege=>cr)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>rr)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>ur)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>dr)
  end

  def self.calendars(cm, cp, um)
    # calendar privileges
    rc = Badges::Privilege.find_or_create_by_name(:name=>"read calendars")
    uc = Badges::Privilege.find_or_create_by_name(:name=>"update calendars")

    # company managers can manage all calendars
    Badges::RolePrivilege.create(:role=>cm, :privilege=>rc)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>uc)

    # user managers can manage a user's calendar
    Badges::RolePrivilege.create(:role=>um, :privilege=>rc)
    Badges::RolePrivilege.create(:role=>um, :privilege=>uc)
    
    # company providers can read calendars
    Badges::RolePrivilege.create(:role=>cp, :privilege=>rc)
  end
  
  def self.services(cm, cp, um)
    # services privileges
    cs = Badges::Privilege.find_or_create_by_name(:name=>"create services")
    rs = Badges::Privilege.find_or_create_by_name(:name=>"read services")
    us = Badges::Privilege.find_or_create_by_name(:name=>"update services")
    ds = Badges::Privilege.find_or_create_by_name(:name=>"delete services")

    # company managers can manage services
    Badges::RolePrivilege.create(:role=>cm, :privilege=>cs)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>rs)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>us)
    Badges::RolePrivilege.create(:role=>cm, :privilege=>ds)

    # company providers can read services
    Badges::RolePrivilege.create(:role=>cp, :privilege=>rs)
  end
  
  def self.appointments(cm, am)
    ma = Badges::Privilege.find_or_create_by_name(:name=>"manage appointments")
    
    # company mangers can manage all appointments
    Badges::RolePrivilege.create(:role=>cm, :privilege=>ma)
    
    # appointment managers can manage their own appointments
    Badges::RolePrivilege.create(:role=>am, :privilege=>ma)
  end

  def self.add_company_staff
    # find all companies with providers
    Company.all(:conditions => ["providers_count > 0"]).each do |company|
      puts "*** adding company staff to #{company.name}"
      company.authorized_managers_and_providers.each do |user|
        next if user.has_role?('company staff', company)
        company.grant_role('company staff', user)
      end
    end
    true
  end

end