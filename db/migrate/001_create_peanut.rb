class CreatePeanut < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name
      t.string :subdomain
      
      t.timestamps
    end
    
    create_table :services do |t|
      t.integer :company_id
      t.string  :name
      t.integer :duration
      t.string  :mark_as
      
      t.timestamps
    end
  
    create_table :resources do |t|
      t.integer :company_id
      t.string  :name

      t.timestamps
    end

    create_table :customers do |t|
      t.string :name
      t.string :email
      t.string :phone

      t.timestamps
    end
    
    create_table :appointments do |t|
      t.integer   :company_id
      t.integer   :service_id
      t.integer   :resource_id
      t.integer   :customer_id
      t.datetime  :start_at
      t.datetime  :end_at
      t.integer   :duration
      t.string    :mark_as
      t.string    :confirmation_code
      
      t.timestamps
    end
  end

  def self.down
    drop_table :appointments
    drop_table :customers
    drop_table :resources
    drop_table :services
    drop_table :companies
  end
end
