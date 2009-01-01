class CreatePeanut < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name
      t.string :subdomain
      
      t.timestamps
    end
    
    add_index :companies, [:subdomain]
    
    create_table :services do |t|
      t.integer :company_id
      t.string  :name
      t.integer :duration
      t.string  :mark_as
      t.integer :price_in_cents
      
      t.timestamps
    end

    add_index :services, [:company_id, :mark_as]

    create_table :products do |t|
      t.integer   :company_id
      t.string    :name
      t.integer   :inventory
      t.integer   :price_in_cents
      
      t.timestamps
    end
  
    # Polymorphic relationship mapping companies to different resources (e.g. people)
    create_table :companies_resources do |t|
      t.references  :company
      t.references  :resource, :polymorphic => true

      t.timestamps
    end

    add_index :companies_resources, [:company_id, :resource_id, :resource_type]

    # Polymorphic relationship mapping services to different resources (e.g. people)
    create_table :memberships do |t|
      t.references  :service
      t.references  :resource, :polymorphic => true

      t.timestamps
    end

    add_index :memberships, [:service_id, :resource_id, :resource_type]
    
    # Polymorphic resource type
    create_table :people do |t|
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
      t.integer     :company_id
      t.integer     :service_id
      t.references  :resource, :polymorphic => true
      t.integer     :customer_id
      t.datetime    :start_at
      t.datetime    :end_at
      t.integer     :duration
      t.integer     :time_start_at  # time of day
      t.integer     :time_end_at    # time of day
      t.string      :mark_as
      t.string      :state
      t.string      :confirmation_code
      
      t.timestamps
    end

    create_table :appointment_invoice_line_items do |t|
      t.integer     :appointment_invoice_id
      t.references  :chargeable, :polymorphic => true
      t.integer     :price_in_cents
      t.integer     :tax
      
      t.timestamps
    end
    
    create_table :appointment_invoices do |t|
      t.integer   :appointment_id
      t.integer   :gratuity_in_cents
      
      t.timestamps
    end
    
    create_table :notes do |t|
      t.text  :comment
      
      t.timestamps
    end
    
    # Polymorphic relationship mapping notes to different subjects (e.g. people, appointments)
    create_table :notes_subjects do |t|
      t.references  :note
      t.references  :subject, :polymorphic => true
    end
    
  end

  def self.down
    drop_table :appointments
    drop_table :customers
    drop_table :companies_resources
    drop_table :people
    drop_table :services
    drop_table :companies
  end
end
