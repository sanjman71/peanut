require 'test/test_helper'

class CompanyTest < ActiveSupport::TestCase

  # shoulda
  should_require_attributes :name
  should_require_attributes :time_zone
  
  context "create company" do
    setup do
      @company = Company.create(:name => "mary's-hair Salon", :time_zone => "UTC")
      assert @company.valid?
    end
    
    should "format and set subdomain" do
      assert_equal "maryshairsalon", @company.subdomain
    end
    
    should "titleize and format name" do
      assert_equal "Mary's Hair Salon", @company.name
    end
    
    should "create basic services" do
      assert_equal 1, @company.services_count
      assert_equal 0, @company.work_services_count
      assert_equal 1, @company.services.free.size
      assert_equal false, @company.can_schedule_appointments?
    end

    should "have locations_count == 0" do
      assert_equal 0, @company.locations_count
    end
    
    context "add location" do
      setup do
        @chicago = Location.new(:name => 'Chicago')
        @company.locations.push(@chicago)
        @company.reload
      end
      
      should_change "Location.count", :by => 1
      
      should "have company location" do
        assert_equal [@chicago], @company.locations
      end
      
      should "increment locations count" do
        assert_equal 1, @company.locations_count
      end
    end
  end
  
end
