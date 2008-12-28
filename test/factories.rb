require 'factory_girl'

Factory.define :company do |c|
  c.name "Company 1"
end

Factory.define :person do |p|
  p.name "Person 1"
end

Factory.define :work_service, :class => Service do |s|
  s.name "Work"
  s.mark_as "work"
  s.duration 30
end

Factory.define :free_service, :class => Service do |s|
  s.name "Available"
  s.mark_as "free"
  s.duration 0
  s.price 0.00
end

Factory.define :product do |p|
  p.name "Product 1"
  p.inventory 1
  p.price_in_cents 100
end

Factory.define :customer do |c|
  c.name { |s| Factory.next :name }
  c.email { |s| Factory.next :email }
  c.phone "6505551212"
end

Factory.sequence :name do |n|
  "user#{n}"
end

Factory.sequence :email do |n|
  "user#{n}@peanut.com"
end
