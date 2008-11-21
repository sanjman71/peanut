class Customer < ActiveRecord::Base
  validates_presence_of       :name, :email, :phone
  validates_uniqueness_of     :name
  has_many                    :appointments

  named_scope :search_name, lambda { |s| { :conditions => ["LOWER(name) REGEXP '%s'", s.downcase] }}
  
  # TODO: search customers associated with a company
  named_scope :company_appointments, :include => :appointments, :conditions => ["appointments.company_id != '0'"]
  
  def self.nobody(options={})
    c = Customer.new do |o|
      o.name = options[:name] || ""
      o.send(:id=, 0)
    end
  end

  # return true if its the special customer 'nobody'
  def nobody?
    self.id == 0
  end
end
