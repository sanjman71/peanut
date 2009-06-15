class Location < ActiveRecord::Base

  # Use GeoKit for mapping
  # acts_as_mappable
  
  # Ensure that the address is geocoded on creation and update
  # before_validation :geocode_address

  # validates_presence_of :city
  # validates_presence_of :country

  has_many_polymorphs :locatables, :from => [:companies, :appointments], :through => :locatables_locations

  # Make sure only accessible attributes are written to from forms etc.
  # attr_accessible :name, :street_address, :city, :state, :zip, :country, :lat, :lng, :phone, :email, :notes
	attr_accessible :name, :street_address, :city, :city_id, :state, :state_id, :zip, :zip_id, :country, :country_id, :lat, :lng, :phone, :email, :notes
	
  COUNTRIES = [
    ['USA', 'us'],
    ['Canada', 'ca'], 
    ['Ireland', 'ie'], 
    ['UK', 'uk']
    ]

	LIMIT_BY_DISTANCE_OPTIONS = [
	  ['No Limit', '0'], 
	  ['2 miles', '2'],
	  ['5 miles', '5'],
	  ['10 miles', '10'],
	  ['20 miles', '20']
  ]

  def geocoded?
    lat && !lat.blank? && lng && !lng.blank?
  end
  
  def lat_rad
    (Math::PI / 180.0) * lat if lat
  end
  
  def lng_rad
    (Math::PI / 180.0) * lng if lng
  end
  
  def self.anywhere
    Location.new do |l|
      l.name = "Anywhere"
      l.send(:id=, 0)
    end
  end
  
  # return true if its the special 'anywhere' location
  def anywhere?
    self.id == 0
  end
  
  protected

  def geocode_address
    if addr_is_blank?
      self.errors.add(:base, "Address is blank")
    else
      geo=GeoKit::Geocoders::MultiGeocoder.geocode(geocodable_address)
      if (!geo.success)
        self.errors.add(:base, "Could not Geocode address")
      else
        self.lat, self.lng = geo.lat,geo.lng if geo.success
        self.city = geo.city if self.city.blank?
        self.state = geo.state if self.state.blank?
        self.zip = geo.zip if self.zip.blank?
      end
    end
  end
    
  def geocodable_address
    country_name = COUNTRIES.detect {|country_pair| country_pair[1] == country}
    country_name = country_name ? country_name[0] : country
    result = ""
    result += street_address + ', ' unless street_address.blank?
    result += city + ', ' unless city.blank?
    result += state + ' ' unless state.blank?
    result += zip + ', ' unless zip.blank?
    result += country_name unless country_name.blank?
    result
  end
  
  def addr_is_blank?
    (street_address.nil? || (street_address && street_address.blank?)) && 
    (city.nil? || (city && city.blank?)) && 
    (state.nil? || (state && state.blank?)) && 
    (zip.nil? || (zip && zip.blank?))
  end

end
