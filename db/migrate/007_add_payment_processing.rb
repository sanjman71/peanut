class AddPaymentProcessing < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.references  :subscription
      t.string      :description 
      t.integer     :amount
      t.string      :state, :default => 'pending'
      t.boolean     :success 
      t.string      :reference 
      t.string      :message 
      t.string      :action 
      t.text        :params 
      t.boolean     :test
      t.timestamps
    end  
    
    create_table :subscriptions do |t|
      t.integer     :time_value, :null => false     # e.g. 1, 5, 30
      t.string      :time_unit, :null => false      # e.g. days, months
      t.integer     :amount
      t.datetime    :start_payment_at
      t.datetime    :last_payment_at
      t.datetime    :next_payment_at
      t.string      :vault_id, :default => nil
      t.string      :state, :default => 'initialized'
      t.timestamps
    end
  end

  def self.down
    drop_table  :payments
    drop_table  :subscriptions
  end
end
