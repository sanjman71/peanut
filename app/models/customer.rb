class Customer < ActiveRecord::Base
  validates_presence_of       :name, :email, :phone
  validates_uniqueness_of     :name
  has_many                    :appointments
end
