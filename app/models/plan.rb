class Plan < ActiveRecord::Base
  validates_presence_of   :name, :cost
  has_many                :subscriptions
  has_many                :users, :through => :subscriptions
  has_many                :companies, :through => :subscriptions
  
  named_scope             :order_by_cost, { :order => :cost }
  
  def is_eligible(company)
    (
      (self.max_locations.blank? || (company.locations.size <= self.max_locations)) &&
      (self.max_resources.blank? || (company.resources.size <= self.max_resources))
    )
  end
  
  def may_add_location?(company)
    (self.max_locations.blank? || (company.locations.size < self.max_locations))
  end
  
  def may_add_resource?(company)
    (self.max_resources.blank? || (company.resources.size < self.max_resources))
  end
  
  # calculate and return start billing time in utc format based on current time or passed in time (defaults to current time)
  def start_billing_at(options={})
    return nil if self.start_billing_in_time_amount.blank? or self.start_billing_in_time_unit.blank?
    start_at = (options[:from] ? options[:from] : Time.now).utc
    (start_at + eval("#{self.start_billing_in_time_amount}.#{self.start_billing_in_time_unit}")).beginning_of_day
  end
  
  # calculate and return the specified number of billing cycles
  def billing_cycle(count=1)
    return 0 if self.between_billing_time_amount.blank? or self.between_billing_time_unit.blank?
    # build cycle count
    cycles = count * self.between_billing_time_amount
    eval("#{cycles}.#{self.between_billing_time_unit}")
  end
  
end
