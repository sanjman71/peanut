require 'factory_girl'

Factory.define :company do |c|
  c.name        "Company 1"
  c.time_zone   "Central Time (US & Canada)"
end

Factory.define :location do |l|
  l.name        "Location 1"
  l.street_addr "123 Broadway"
  l.city        "New York"
  l.state       "CA"
  l.zip         "12345"
end

Factory.define :person do |p|
  p.name "Person 1"
end

Factory.define :work_service, :class => Service do |s|
  s.name      "Work"
  s.mark_as   "work"
  s.duration  30
end

Factory.define :free_service, :class => Service do |s|
  s.name      "Available"
  s.mark_as   "free"
  s.duration  0
  s.price     0.00
end

Factory.define :product do |p|
  p.name            "Product 1"
  p.inventory       1
  p.price_in_cents  100
end

Factory.define :user do |u|
  u.name                    { |s| Factory.next :name }
  u.email                   { |s| Factory.next :email }
  u.password                "peanut"
  u.password_confirmation   "peanut"
end

Factory.define :customer do |c|
  c.name { |s| Factory.next :customer_name }
  c.email { |s| Factory.next :customer_email }
  c.phone "6505551212"
end

# Factory.define :appointment do |a|
#   a.mark_as     { |o| o.service.mark_as }
# end

Factory.define :appointment_today, :class => Appointment do |a|
  a.mark_as         { |o| o.service.mark_as }
  a.start_at        { |o| Factory.next :today_hour }  # choose an hour from today
  a.duration        { |o| o.service.duration_to_seconds }
  a.end_at          { |o| o.start_at + o.service.duration_to_seconds }  # add duration to start_at
end

Factory.sequence :name do |n|
  "user#{n}"
end

Factory.sequence :customer_name do |n|
  "Customer #{n}"
end

Factory.sequence :email do |n|
  "user#{n}@peanut.com"
end

Factory.sequence :customer_email do |n|
  "customer#{n}@peanut.com"
end

Factory.sequence :today_hour do |n|
  Time.now.beginning_of_day + n.hours
end
