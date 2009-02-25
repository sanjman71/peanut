class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.timestamps
      t.references  :user
      # Account info includes address, credit card info etc - though much of this is likely stored at a processing site
      # what do we need here? Support for ActiveMerchant repeat charges, for example?
      t.string      :street1
      t.string      :street2
      t.string      :city
      t.string      :state
      t.string      :zip
    end
    
    create_table :plans do |t|
      t.timestamps
      t.string      :name
      t.string      :textid
      t.string      :icon
      t.decimal     :cost
      t.string      :cost_currency
      t.integer     :max_locations
      t.integer     :max_resources
      t.integer     :days_to_first_bill
      t.integer     :months_between_bills
    end
    
    create_table :plan_subscriptions do |t|
      t.timestamps
      t.references  :user
      t.references  :company
      t.references  :plan
      t.datetime    :next_bill_date
    end
    
  end

  def self.down
    drop_table :plan_subscriptions
    drop_table :plans
    drop_table :accounts
  end
end
