require 'test/test_helper'

class CompanyTest < ActiveSupport::TestCase

  should_require_attributes   :name
  should_require_attributes   :time_zone
  should_have_many            :services
  should_have_many            :products
  should_have_many            :appointments
  should_have_many            :invitations
  should_have_many            :companies_resources
  
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
    
    should "with basic services" do
      assert_equal 1, @company.services_count
      assert_equal 0, @company.work_services_count
      assert_equal 1, @company.services.free.size
      assert_equal false, @company.can_schedule_appointments?
    end

    should "have locations_count == 0" do
      assert_equal 0, @company.locations_count
    end
    
    context "with a location" do
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
    
    context "with a user resource" do
      setup do 
        @user1 = Factory(:user, :name => "User Resource")
        assert_valid @user1
        @company.resources.push(@user1)
      end
      
      should "have company resources collection == [@user1]" do
        assert_equal [@user1], @company.resources
      end
      
      should "have has_resource? return true" do
        assert @company.has_resource?(@user1)
      end
    end
  end
  
end
