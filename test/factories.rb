require 'factory_girl'

Factory.define :company do |c|
  c.name        "Company 1"
  c.subdomain   "company1"
  c.time_zone   "Central Time (US & Canada)"
end

Factory.define :us, :class => Country do |o|
  o.name        "United States"
  o.code        "US"
end

Factory.define :il, :class => State do |i|
  i.name        "Illinois"
  i.code        "IL"
  i.country     { |i| i.association :us }
end

Factory.define :chicago, :class => City do |o|
  o.name        "Chicago"
  o.state       { |c| c.association :il }
end

Factory.define :zip, :class => Zip do |o|
  o.name        "60654"
  o.state       { |z| z.association :il }
end

Factory.define :neighborhood, :class => Neighborhood do |o|
  o.name        "River North"
  o.city        { |o| o.association :chicago }
end

Factory.define :location, :class => Location do |l|
  l.name            "Broadway location"
  l.street_address  "123 Broadway"
  l.city            { |l| l.association :chicago }
  l.state           { |l| l.association :il }
  l.zip             { |l| l.association :zip }
  l.country         { |l| l.association :us }
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
  s.price     0.00
  # no duration required for free services
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
  u.state                 "active"    # always create users in active state
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
  o.max_providers                 1
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

Factory.define :log_entry do |e|
  e.message_id                    LogEntriesHelper::LOG_ENTRY_MESSAGE_IDS[:appointment_confirmation]
  e.message_body                  "This is a test appointment confirmation log_entry"
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
