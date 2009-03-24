class CreatePeanut < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string  :name
      t.string  :time_zone
      t.string  :subdomain
      t.string  :slogan
      t.text    :description
      t.integer :locations_count, :default => 0       # counter cache
      t.integer :services_count, :default => 0        # counter cache
      t.integer :work_services_count, :default => 0   # counter cache
      t.integer :schedulables_count, :default => 0    # counter cache
      t.timestamps
    end
    
    add_index :companies, [:subdomain]
    
    create_table :services do |t|
      t.string  :name
      t.integer :duration
      t.string  :mark_as
      t.integer :price_in_cents
      t.integer :schedulables_count, :default => 0          # counter cache
      t.boolean :allow_custom_duration, :default => false   # by default no custom duration
      
      t.timestamps
    end

    add_index :services, [:mark_as]

    # create free service used by all companies
    Service.create(:name => Service::AVAILABLE, :duration => 0, :mark_as => "free", :price => 0.00)
    
    # map services to companies
    create_table :company_services do |t|
      t.integer :company_id
      t.integer :service_id
    end

    add_index :company_services, [:company_id]
    add_index :company_services, [:service_id]
    
    create_table :products do |t|
      t.integer   :company_id
      t.string    :name
      t.integer   :inventory
      t.integer   :price_in_cents
      t.timestamps
    end
  
    add_index :products, [:company_id]
    add_index :products, [:company_id, :name]

    # Map polymorphic schedulablesd (e.g. users) to companies
    create_table :company_schedulables do |t|
      t.references  :company
      t.references  :schedulable, :polymorphic => true
      t.timestamps
    end
    
    add_index :company_schedulables, [:schedulable_id, :schedulable_type], :name => 'index_on_schedulables'
    add_index :company_schedulables, [:company_id, :schedulable_id, :schedulable_type], :name => 'index_on_companies_and_schedulables'

    # Polymorphic relationship mapping services to schedulables (e.g. users)
    create_table :service_providers do |t|
      t.references  :service
      t.references  :schedulable, :polymorphic => true
      t.timestamps
    end

    add_index :service_providers, [:service_id, :schedulable_id, :schedulable_type], :name => 'index_on_services_and_schedulable'
    
    create_table :mobile_carriers do |t|
      t.string :name
      t.string :key   # used by SMSFu plugin to find carrier's email gateway address
    end
    
    # Create default mobile carriers
    MobileCarrier.create(:name => 'Alltel Wireless',    :key => 'alltel')
    MobileCarrier.create(:name => 'AT&T/Cingular',      :key => 'at&t')
    MobileCarrier.create(:name => 'Boost Mobile',       :key => 'boost')
    MobileCarrier.create(:name => 'Sprint Wireless',    :key => 'sprint')
    MobileCarrier.create(:name => 'T-Mobile US',        :key => 't-mobile')
    MobileCarrier.create(:name => 'T-Mobile UK',        :key => 't-mobile-uk')
    MobileCarrier.create(:name => 'Virgin Mobile',      :key => 'virgin')
    MobileCarrier.create(:name => 'Verizon Wireless',   :key => 'verizon')
        
    create_table :appointments do |t|
      t.integer     :company_id
      t.integer     :service_id
      t.references  :schedulable, :polymorphic => true    # e.g. users
      t.integer     :customer_id       # user who booked the appointment
      t.string      :when
      t.datetime    :start_at
      t.datetime    :end_at
      t.integer     :duration
      t.string      :time
      t.integer     :time_start_at  # time of day
      t.integer     :time_end_at    # time of day
      t.string      :mark_as
      t.string      :state
      t.string      :confirmation_code
      t.integer     :locations_count, :default => 0     # locations counter cache
      t.timestamps
    end

    add_index :appointments, [:company_id, :start_at, :end_at, :duration, :time_start_at, :time_end_at, :mark_as], :name => "index_on_openings"
    
    create_table :invoice_line_items do |t|
      t.integer     :invoice_id
      t.references  :chargeable, :polymorphic => true
      t.integer     :price_in_cents
      t.integer     :tax
      t.timestamps
    end
    
    create_table :invoices do |t|
      t.references  :invoiceable, :polymorphic => true
      t.integer     :gratuity_in_cents
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
    drop_table :companies
    drop_table :appointments
    drop_table :people
    drop_table :services
    drop_table :calendars
    drop_table :service_providers
    drop_table :notes
  end
end
