class CreateDefaultRolesPrivs < ActiveRecord::Migration
  def self.up
    cm = Badges::Role.create(:name=>"company manager")
    ce = Badges::Role.create(:name=>"company employee")

    cc = Badges::Privilege.create(:name=>"create company")
    rc = Badges::Privilege.create(:name=>"read company")
    uc = Badges::Privilege.create(:name=>"update company")
    dc = Badges::Privilege.create(:name=>"delete company")
    
    # Company manager can read & update company
    Badges::RolePrivilege.create(:role=>cm,:privilege=>rc) unless cm.nil? || rc.nil?
    Badges::RolePrivilege.create(:role=>cm,:privilege=>uc) unless cm.nil? || uc.nil?
    
    # Company employee can read company
    Badges::RolePrivilege.create(:role=>ce,:privilege=>rc) unless ce.nil? || rc.nil?
  end

  def self.down
    Badges::Role.find(:first, :conditions=>{:name=>"company manager"}).destroy
    Badges::Role.find(:first, :conditions=>{:name=>"company employee"}).destroy

    Badges::Privilege.find(:first, :conditions=>{:name=>"create company"}).destroy
    Badges::Privilege.find(:first, :conditions=>{:name=>"read company"}).destroy
    Badges::Privilege.find(:first, :conditions=>{:name=>"update company"}).destroy
    Badges::Privilege.find(:first, :conditions=>{:name=>"delete company"}).destroy
  end
end
