class Customer < ActiveRecord::Base
  validates_presence_of       :name, :email, :phone
  validates_uniqueness_of     :email
  has_many                    :appointments
  has_many                    :companies, :through => :appointments, :uniq => true
  belongs_to                  :mobile_carrier
  
  named_scope                 :search_name, lambda { |s| { :conditions => ["LOWER(name) REGEXP '%s'", s.downcase] }}
  
  def self.nobody(options={})
    c = Customer.new do |o|
      o.name = options[:name] || ""
      o.send(:id=, 0)
    end
  end

  # returns true if its the special customer 'nobody'
  def nobody?
    self.id == 0
  end

  # returns true if the customer has a valid sms address
  def sms?
    !mobile_carrier.blank?
  end

end
