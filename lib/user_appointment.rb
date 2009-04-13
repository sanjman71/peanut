module UserAppointment
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
      
      # users have many appointments
      has_many    :appointments, :foreign_key => 'customer_id'
    end
  end

  module ClassMethods
  end # class methods
  
  module InstanceMethods
  end # instance methods
end