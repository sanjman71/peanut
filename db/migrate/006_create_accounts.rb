class CreateAccounts < ActiveRecord::Migration
  def self.up
    # create_table :accounts do |t|
    #   t.timestamps
    #   t.references  :user
    #   # Account info includes address, credit card info etc - though much of this is likely stored at a processing site
    #   # what do we need here? Support for ActiveMerchant repeat charges, for example?
    #   t.string      :street1
    #   t.string      :street2
    #   t.string      :city
    #   t.string      :state
    #   t.string      :zip
    # end
    
    create_table :plans do |t|
      t.string      :name
      t.string      :textid
      t.string      :icon
      t.decimal     :cost   # value in cents
      t.string      :cost_currency
      t.integer     :max_locations
      t.integer     :max_resources
      t.integer     :start_billing_in_time_amount   # e.g. 1, 5, 30
      t.string      :start_billing_in_time_unit     # e.g. days, months
      t.integer     :between_billing_time_amount    # e.g. 1, 5, 30
      t.string      :between_billing_time_unit      # e.g. days, months

      t.timestamps
    end
    
    # create_table :plan_subscriptions do |t|
    #   t.timestamps
    #   t.references  :user
    #   t.references  :company
    #   t.references  :plan
    #   t.datetime    :next_bill_date
    # end
    
  end

  def self.down
    drop_table :plans
  end
end
