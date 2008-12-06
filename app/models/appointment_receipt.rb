class AppointmentReceipt < ActiveRecord::Base
  belongs_to  :appointment
end