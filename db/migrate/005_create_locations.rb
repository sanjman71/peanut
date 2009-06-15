class CreateLocations < ActiveRecord::Migration
  def self.up
    
    create_table :countries do |t|
      t.string      :name,                  :limit => 30, :default => nil
      t.string      :code,                  :limit => 2, :default => nil
      t.integer     :locations_count,       :default => 0   # counter cache
    end

    add_index :countries, :code
    add_index :countries, :locations_count

    create_table :states do |t|
      t.string      :name,                  :limit => 30, :default => nil
      t.string      :code,                  :limit => 2, :default => nil
      t.references  :country
      t.decimal     :lat,                   :precision => 15, :scale => 10
      t.decimal     :lng,                   :precision => 15, :scale => 10
      t.integer     :cities_count,          :default => 0   # counter cache
      t.integer     :zips_count,            :default => 0   # counter cache
      t.integer     :locations_count,       :default => 0   # counter cache
      t.integer     :events,                :default => 0
    end

    add_index :states, :country_id
    add_index :states, [:country_id, :locations_count]
    add_index :states, [:country_id, :code]

    create_table :cities do |t|
      t.string      :name,                  :limit => 30, :default => nil
      t.references  :state
      t.decimal     :lat,                   :precision => 15, :scale => 10
      t.decimal     :lng,                   :precision => 15, :scale => 10
      t.integer     :neighborhoods_count,   :default => 0   # counter cache
      t.integer     :locations_count,       :default => 0   # counter cache
    end

    add_index :cities, :state_id
    add_index :cities, :locations_count
    add_index :cities, [:state_id, :locations_count], :name => "index_cities_on_state_and_locations"
    add_index :cities, [:state_id, :name], :name => "index_cities_on_state_and_name"

    create_table :zips do |t|
      t.string      :name,                  :limit => 10, :default => nil
      t.references  :state
      t.decimal     :lat,                   :precision => 15, :scale => 10
      t.decimal     :lng,                   :precision => 15, :scale => 10
      t.integer     :locations_count,       :default => 0   # counter cache
    end

    add_index :zips, :state_id
    add_index :zips, [:state_id, :locations_count]

    create_table :locations do |t|

      # This location's name
      t.string :name, :default => nil

      # This location's address
    	t.string :street_address, :string
      # t.string :city, :string
      # t.string :state, :string
      # t.string :zip, :string
      # t.string :country
      t.references  :city
      t.references  :state
      t.references  :zip
      t.references  :country

      # This location's phone and email address
      t.string :phone
      t.string :email
      
      # Notes about this location
      t.text :notes

      # Lat and Lng for this location, if it has been geocoded
    	t.decimal :geocode_lat, :precision => 15, :scale => 10
    	t.decimal :geocode_long, :precision => 15, :scale => 10

      t.timestamps
      t.integer :lock_version, :default => 0, :null => false
    end

    add_index :locations, [:name]
    
    create_table :locatables_locations do |t|
      t.references :location
      t.references :locatable, :polymorphic => true
    end
    
    add_index :locatables_locations, [:location_id]
    add_index :locatables_locations, [:locatable_id, :locatable_type], :name => "index_on_locatables"
    add_index :locatables_locations, [:location_id, :locatable_id, :locatable_type], :name => "index_on_locations_locatables"
  end

  def self.down
    drop_table :locatables_locations
    drop_table :locations
  end
end
