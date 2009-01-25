class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|

      # This location's name
      t.string :name, :default => nil

      # This location's address
    	t.string :street_addr, :string
    	t.string :city, :string
    	t.string :state, :string
    	t.string :zip, :string
    	t.string :country

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
    
    create_table :locatables_locations do |t|
      t.references :location
      t.references :locatable, :polymorphic => true
    end
    
  end

  def self.down
    drop_table :locatables_locations
    drop_table :locations
  end
end