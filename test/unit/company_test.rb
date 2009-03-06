require 'test/test_helper'

class CompanyTest < ActiveSupport::TestCase

  should_require_attributes   :name
  should_require_attributes   :subdomain
  should_require_attributes   :time_zone
  should_have_one             :subscription
  should_have_many            :services
  should_have_many            :products
  should_have_many            :appointments
  should_have_many            :invitations
  should_have_many            :calendars
  
  context "create company without a subscription" do
    setup do
      @company = Company.create(:name => "mary's-hair Salon", :time_zone => "UTC")
    end
    
    should_not_change "Company.count"
    
    should "require a valid subscription" do
      assert_equal "Subscription is not valid", @company.errors.on_base
    end
  end

  context "create company with a subscription" do
    setup do
      @user         = Factory(:user)
      @plan         = Factory(:monthly_plan)
      @subscription = Subscription.new(:user => @user, :plan => @plan)
      @company      = Company.create(:name => "mary's-hair Salon", :time_zone => "UTC", :subscription => @subscription)
      assert_valid @subscription
      assert_valid @company
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
    
    context "add a location" do
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
    
    context "add a user schedulable" do
      setup do 
        @user1 = Factory(:user, :name => "User Resource")
        assert_valid @user1
        @company.schedulables.push(@user1)
        @company.reload
      end
      
      should "have company schedulables collection == [@user1]" do
        assert_equal [@user1], @company.schedulables
      end
      
      should "have company.has_schedulable?(user) return true" do
        assert @company.has_schedulable?(@user1)
      end
      
      should "have calendar count == 1" do
        assert_equal 1, @company.calendars_count
      end
      
      should "have users.has_calendar?(company) return true" do
        assert @user1.has_calendar?(@company)
      end
    end
  end
  
end
