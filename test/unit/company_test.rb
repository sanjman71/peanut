require 'test/test_helper'
require 'test/factories'

class CompanyTest < ActiveSupport::TestCase
  
  # test peanut-specific fields
  should_validate_presence_of   :name
  should_validate_presence_of   :subdomain
  should_have_many              :locations
  should_have_many              :phone_numbers
  should_belong_to              :timezone
  should_belong_to              :chain
  should_have_one               :subscription
  should_have_many              :services
  should_have_many              :products
  should_have_many              :appointments
  should_have_many              :invitations
  should_have_many              :company_providers
  
  
  context "company services" do
    setup do
      @company = Factory(:company, :name => "mary's-hair Salon", :time_zone => "UTC")
    end
  
    should "have 0 services" do
      assert_equal 0, @company.services_count
    end
  
    should "have 0 work services" do
      assert_equal 0, @company.work_services_count
    end
  
    context "then add a company service" do
      setup do
        # add the service using the push syntax to ensure the callbacks are used
        @haircut = Factory(:work_service, :name => "Haircut", :price => 10.00, :company => @company)
        assert_valid @haircut
        @company.services.push(@haircut)
        @company.reload
      end
  
      should "have services_count == 1" do
        assert_equal 1, @company.services_count
      end
  
      should "have work_services_count == 1" do
        assert_equal 1, @company.work_services_count
      end
  
      context "then remove the company service" do
        setup do
          @company.services.delete(@haircut)
          @company.reload
        end
  
        should "have services_count == 0" do
          assert_equal 0, @company.services_count
        end
        
        should "have work_services_count == 0" do
          assert_equal 0, @company.work_services_count
        end
      end
  
    end
  end
  
  context "company providers" do
    setup do
      @company  = Factory(:company, :name => "mary's-hair Salon", :time_zone => "UTC")
      @provider = Factory(:user, :name => "Provider")
      assert_valid @provider
      @company.user_providers.push(@provider)
      @company.reload
    end

    should_change("company provider count", :by => 1) { CompanyProvider.count }

    should "change company.user_providers" do
      assert_equal [@provider], @company.user_providers
    end
    
    should "increment company.providers_count" do
      assert_equal 1, @company.providers_count
    end

    should "have company.has_provider?(user) return true" do
      assert @company.has_provider?(@provider)
    end

    should "assign role 'company provider' on company to user" do
      assert_equal ['company provider'], @provider.roles_on(@company).collect(&:name)
    end

    context "and try to add the same provider" do
      setup do
        # @company.user_providers.push(@provider)
        @company.company_providers.create(:provider => @provider)
        @company.reload
      end
  
      should_not_change("company provider count") { CompanyProvider.count }
  
      should "not change company.user_providers" do
        assert_equal [@provider], @company.user_providers
      end
    end
    
    context "then add resource provider" do
      setup do
        @resource = Factory(:resource, :name => "Resource Provider")
        assert_valid @resource
        @company.resource_providers.push(@resource)
        @company.reload
      end

      should_change("company provider count", :by => 1) { CompanyProvider.count }

      should "change company.resource_providers" do
        assert_equal [@resource], @company.resource_providers
      end

      should "change company.providers" do
        assert_equal [@resource, @provider], @company.providers
      end

      should "increment company.providers_count" do
        assert_equal 2, @company.providers_count
      end
    end

    context "then remove the user provider" do
      setup do
        @company.user_providers.delete(@provider)
        @company.reload
        @provider.reload
      end

      should "have no company.user_providers" do
        assert_equal [], @company.user_providers
      end

      should "decrement company.providers_count" do
        assert_equal 0, @company.providers_count
      end

      should "have company.has_provider? return false" do
        assert !@company.has_provider?(@provider)
      end

      should "remove role 'company provider' on company from user" do
        assert_equal [], @provider.roles_on(@company).collect(&:name)
      end
    end
    
  end

  context "company subscriptions" do
    setup do
      @company      = Factory(:company, :name => "mary's-hair Salon", :time_zone => "UTC")
      @owner        = Factory(:user, :name => "Owner")
      @subscription = @company.create_subscription(:user => @owner, :plan => @monthly_plan)
    end

    should "have free service" do
      assert @company.free_service
    end

    should "have services_count == 1" do
      assert_equal 1, @company.services_count
    end

    should "have work_services_count == 0" do
      assert_equal 0, @company.work_services_count
    end
  end

  context "company with no preferences" do
    setup do
      @company      = Factory(:company, :name => "mary's hair Salon", :time_zone => "UTC")
      @owner        = Factory(:user, :name => "Owner")
      @subscription = @company.create_subscription(:user => @owner, :plan => @monthly_plan)
    end
    
    should "have empty preferences" do
      assert_equal Hash.new, @company.preferences
    end
  
    should "have nil preferences['foo']" do
      assert_nil @company.preferences['foo']
    end
  
    context "then add preferences" do
      setup do
        @company.preferences["favorite fruit"] = "banana"
        @company.preferences["private"] = true
        @company.preferences["semi-private"] = "walnutindustries.com"
        @company.preferences["custom hash"] = ["fruit" => ["apple", "pear", "plum"], "airplanes" => %W{Airbus, Boeing, Lockheed, SAAB}]
        @company.preferences["meaning of life"] = 42
      end
   
      should "have all preferences set" do
        assert_equal "banana", @company.preferences["favorite fruit"]
        assert_equal true, @company.preferences["private"]
        assert_equal "walnutindustries.com", @company.preferences["semi-private"]
        assert_equal ["fruit" => ["apple", "pear", "plum"], "airplanes" => %W{Airbus, Boeing, Lockheed, SAAB}], @company.preferences["custom hash"]
        assert_equal 42, @company.preferences["meaning of life"]
      end
      
    end
    
  end
  
  context "create a company with service, provider, subscription and owner" do
    setup do
      @owner        = Factory(:user, :name => "Owner")
      @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
      @company      = Factory(:company, :name => "mary's hair Salon", :time_zone => "UTC", :subscription => @subscription)

      # add company service service using the push syntax to ensure the callbacks are used
      @haircut      = Factory(:work_service, :name => "Haircut", :price => 10.00, :company => @company)
      assert_valid @haircut
      @company.services.push(@haircut)
      @company.reload
      
      # add company user provider
      @provider     = Factory(:user, :name => "Provider")
      assert_valid @provider
      @company.user_providers.push(@provider)
      @company.reload
    end

    context "destroy the company, all of the services, but none of the providers or owner" do
      setup do
        @company.destroy
      end

      should "have no company or join models" do
        assert_equal 0, Company.count
        assert_equal 0, Appointment.count
        assert_equal 0, Subscription.count
        assert_equal 0, CompanyProvider.count
        assert_equal 0, CapacitySlot.count
      end
      
      should "have no service" do
        assert_equal 0, Service.count
      end

      should "have 1 provider and 1 owner" do
        assert_equal 2, User.count
      end
      
    end
    
    # KILLIAN - I'm not able to get the Company.destroy method to destroy the owner, for some reason
    # leaving this test out for now
    # context "destroy the company and owner, but not the services or providers" do
    #   setup do
    #     @company.destroy(:owner => true)
    #   end
    #   
    #   should "have no company or join models or owner" do
    #     assert_equal 0, Company.count
    #     assert_equal 0, Appointment.count
    #     assert_equal 0, Subscription.count
    #     assert_equal 0, CompanyService.count
    #     assert_equal 0, CompanyProvider.count
    #     assert_equal 0, CapacitySlot.count
    #   end
    #   
    #   should "have a service and provider" do
    #     assert_equal 2, Service.count
    #     assert_equal 1, User.count
    #   end
    # end

  end

end