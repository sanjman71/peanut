class Customer < ActiveRecord::Base
  validates_presence_of       :name, :email, :phone
  validates_uniqueness_of     :name
  has_many                    :appointments

  def self.nobody(options={})
    c = Customer.new do |o|
      o.name = options[:name] || ""
      o.id   = 0
    end
  end

end
