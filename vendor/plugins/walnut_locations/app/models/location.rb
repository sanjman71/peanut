class Location < ActiveRecord::Base
  has_many                :locatables_locations
  has_many                :locatables, :through => :locatables_locations

  # All addresses must have a country, state, city and zip
  validates_presence_of   :country_id, :state_id, :city_id, :zip_id

  belongs_to              :country
  belongs_to              :state
  belongs_to              :city
  belongs_to              :zip
  has_many                :location_neighborhoods
  has_many                :neighborhoods, :through => :location_neighborhoods, :after_add => :after_add_neighborhood, :before_remove => :before_remove_neighborhood

  has_many                :phone_numbers, :as => :callable

  after_save              :after_save_callback

  attr_accessor           :city_str, :zip_str, :state_str, :country_str

  # make sure only accessible attributes are written to from forms etc.
	attr_accessible         :name, :country, :country_id, :state, :state_id, :city, :city_id, :zip, :zip_id,
	                        :street_address, :lat, :lng, :city_str, :zip_str, :state_str, :country_str
	
  named_scope :with_state,            lambda { |state| { :conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] }}
  named_scope :with_city,             lambda { |city| { :conditions => ["city_id = ?", city.is_a?(Integer) ? city : city.id] }}
  named_scope :with_neighborhoods,    { :conditions => ["neighborhoods_count > 0"] }
  named_scope :no_neighborhoods,      { :conditions => ["neighborhoods_count = 0"] }
  named_scope :urban_mapped,          { :conditions => ["urban_mapping_at <> ''"] }
  named_scope :not_urban_mapped,      { :conditions => ["urban_mapping_at is NULL"] }
  named_scope :with_phone_numbers,    { :conditions => ["phone_numbers_count > 0"] }
  named_scope :no_phone_numbers,      { :conditions => ["phone_numbers_count = 0"] }
  named_scope :min_phone_numbers,     lambda { |x| {:conditions => ["phone_numbers_count >= ?", x] }}

  def self.anywhere
    Location.new do |l|
      l.name = "Anywhere"
      l.send(:id=, 0)
    end
  end

  # return collection of location's country, state, city, zip, neighborhoods
  def localities
    [country, state, city, zip].compact + neighborhoods.compact
  end

  def primary_phone_number
    return nil if phone_numbers_count == 0
    phone_numbers.first
  end

  # returns true iff the location has a latitude and longitude 
  def mappable?
    return true if self.lat and self.lng
    false
  end

  def refer_to?
    self.refer_to > 0
  end

  def geocode_latlng(options={})
    force = options.has_key?(:force) ? options[:force] : false
    return true if self.lat and self.lng and !force
    # multi-geocoder geocode does not throw an exception on failure
    geo = Geokit::Geocoders::MultiGeocoder.geocode("#{street_address}, #{city.name} #{state.name} #{country}")
    return false unless geo.success
    self.lat, self.lng = geo.lat, geo.lng
    self.save
  end
  
  def validate
    
    # We allow for an address to be put in the string temporary fields, which we'll convert to a geocoded set of references.
    # If the address isn't in these strings, then the database references should be assigned
    if (self.street_address.blank?)
      errors.add(:street_address, "You must enter a street address.")
    elsif (self.city_str.blank?)
      if (self.city.blank?)
        errors.add(:city, "You must enter a city.")
      else
        self.city_str = self.city.name
      end
    elsif (self.state_str.blank? && self.state.blank?)
      if (self.city.blank?)
        errors.add(:state, "You must enter a state.")
      else
        self.state_str = self.state.name
      end
    elsif (self.country_str.blank? && self.country.blank?)
      if (self.city.blank?)
        # Assume the country is the US if none entered
        self.country_str = "US"
      else
        self.country_str = self.country.name
      end
    end

    # Geocode the address. We pull out unit #'s etc from the street address
    sa_components = StreetAddress.components(self.street_address)
    tmp_sa = StreetAddress.normalize("#{sa_components[:housenumber]} #{sa_components[:streetname]}")
      
    geo=GeoKit::Geocoders::MultiGeocoder.geocode("#{tmp_sa} #{self.city_str} #{self.state_str} #{self.country_str}")

    if !geo.success
      errors.add_to_base("Sorry, this address could not be located. Please re-enter it.")
    else
      if (!self.country = Country.find_by_code(geo.country_code))
        errors.add(:country_str, "Sorry, we do not support that country yet.")
      end
      if (!self.state = State.find_or_create_by_code(:code => geo.state, :name => geo.state, :country => country))
        errors.add(:state_str, "Sorry, we had a problem adding the state #{geo.state}.")
      end
      if (!self.zip = Zip.find_or_create_by_name(:name => geo.zip, :state => state))
        errors.add(:zip_str, "Sorry, we had a problem adding the zip #{geo.zip}.")
      end
      if (!self.city = City.find_or_create_by_name(:name => geo.city, :state => state))
        errors.add(:city_str, "Sorry, we had a problem adding the city #{geo.city}.")
      end
    end
    
  end

  protected
  
  # after_save callback to:
  #  - increment/decrement locality counter caches
  #  x (deprecated) update locality tags (e.g. country, state, city, zip) based on changes to the location object
  def after_save_callback
    changed_set = ["country_id", "state_id", "city_id", "zip_id"]
  
    self.changes.keys.each do |change|
      # filter out unless its a locality
      next unless changed_set.include?(change.to_s)
    
      begin
        # get class object
        klass_name  = change.split("_").first.titleize
        klass       = Module.const_get(klass_name)
      rescue
        next
      end
    
      old_id, new_id = self.changes[change]
    
      if old_id
        locality = klass.find_by_id(old_id.to_i)
        # decrement counter cache
        klass.decrement_counter(:locations_count, locality.id)
      end
    
      if new_id
        locality = klass.find_by_id(new_id.to_i)
        # increment counter cache
        klass.increment_counter(:locations_count, locality.id)
      end
    end
  end

  def after_add_neighborhood(hood)
    return if hood.blank?
  end

  def before_remove_neighborhood(hood)
    return if hood.blank?
    # decrement counter caches
    Neighborhood.decrement_counter(:locations_count, hood.id)
    Location.decrement_counter(:neighborhoods_count, self.id)
  end

end
