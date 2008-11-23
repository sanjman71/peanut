class Person < ActiveRecord::Base
  validates_presence_of     :name
  
  named_scope               :search_name, lambda { |s| { :conditions => ["LOWER(name) REGEXP '%s'", s.downcase] }}
  
  # the special anyone person
  def self.anyone
    r = Person.new do |o|
      o.name = "Anyone"
      o.send(:id=, 0)
    end
  end
  
  # return true if its the special person 'anyone'
  def anyone?
    self.id == 0
  end
  
end