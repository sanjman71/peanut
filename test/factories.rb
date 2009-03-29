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
  s.name                    "Work"
  s.mark_as                 "work"
  s.duration                30
  s.allow_custom_duration   false
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
  u.name                  { |s| Factory.next :user_name }
  u.email                 { |s| Factory.next :user_email }
  u.password              "secret"
  u.password_confirmation "secret"
  u.phone                 "9999999999"
end

Factory.define :monthly_plan, :class => Plan do |o|
  o.name                          "Monthly"
  o.cost                          1000  # cents
  o.start_billing_in_time_amount  1
  o.start_billing_in_time_unit    "months"
  o.between_billing_time_amount   1
  o.between_billing_time_unit     "months"
  o.enabled                       true
end

Factory.define :free_plan, :class => Plan do |o|
  o.name                          "Free"
  o.cost                          0  # cents
  o.enabled                       true
  o.max_resources                 1
  o.max_locations                 1
end

Factory.define :subscription do |o|
  o.plan        { |o| Factory(:montly_plan, :name => "Monthly Subscription")}
  o.user        { |o| Factory(:user) }
end

Factory.define :appointment_today, :class => Appointment do |a|
  a.mark_as         { |o| o.service.mark_as }
  a.start_at        { |o| Factory.next :today_hour }  # choose an hour from today
  a.duration        { |o| o.service.duration_to_seconds }
  a.end_at          { |o| o.start_at + o.service.duration_to_seconds }  # add duration to start_at
end

Factory.define :event do |e|
  e.message                       "Test event"
end

Factory.sequence :user_name do |n|
  "User #{n}"
end

Factory.sequence :user_email do |n|
  "user#{n}@peanut.com"
end

Factory.sequence :today_hour do |n|
  Time.now.beginning_of_day + n.hours
end
