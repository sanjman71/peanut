class Plan < ActiveRecord::Base
  validates_presence_of   :name, :cost
  has_many                :subscriptions
  has_many                :users, :through => :subscriptions
  has_many                :companies, :through => :subscriptions
  
  def is_eligible(company)
    (
      (self.max_locations.blank? || (company.locations.size <= self.max_locations)) &&
      (self.max_resources.blank? || (company.resources.size <= self.max_resources))
    )
  end
  
  # calculate and return start billing date based on current time or passed in time (defaults to current time)
  def start_billing_at(options={})
    return nil if self.start_billing_in_time_amount.blank? or self.start_billing_in_time_unit.blank?
    start_at = options[:from] || Time.now
    (start_at + eval("#{self.start_billing_in_time_amount}.#{self.start_billing_in_time_unit}")).to_date
  end
  
  # calculate and return time between billing cycles
  def billing_cycle
    return 0 if self.between_billing_time_amount.blank? or self.between_billing_time_unit.blank?
    eval("#{self.between_billing_time_amount}.#{self.between_billing_time_unit}")
  end
  
end
