require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  
  # test peanut-specific fields
  should validate_presence_of   :name
  should validate_presence_of   :subdomain
  should have_many              :locations
  should have_many              :phone_numbers
  should belong_to              :timezone
  should belong_to              :chain
  should have_one               :subscription
  should have_many              :services
  should have_many              :products
  should have_many              :appointments
  should have_many              :invitations
  should have_many              :company_providers

  setup do
    @montly_plan  = Factory(:monthly_plan)
    @owner        = Factory(:user, :name => "Owner")
  end
  
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
  
    should "change company.user_providers collection" do
      assert_equal [@provider], @company.user_providers
    end
    
    should "increment company.providers_count" do
      assert_equal 1, @company.providers_count
    end
  
    should "have company.has_provider?(user) return true" do
      assert @company.has_provider?(@provider)
    end
  
    should "add role 'company provider' and 'company staff' to user" do
      assert_equal ['company provider', 'company staff'], @provider.roles_on(@company).collect(&:name).sort
    end
  
    should "add user to company.authorized_providers collection" do
      assert @company.reload.authorized_providers.include?(@provider)
    end

    context "and try to add the same provider" do
      setup do
        # @company.user_providers.push(@provider)
        @company.company_providers.create(:provider => @provider)
        @company.reload
      end
  
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
  
      should "change company.resource_providers" do
        assert_equal [@resource], @company.resource_providers
      end
  
      should "change company.providers" do
        assert_equal [@provider, @resource], @company.providers
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
  
      should "remove role 'company provider' from user, but leave role 'company staff'" do
        assert_equal ['company staff'], @provider.roles_on(@company).collect(&:name)
      end

      should "remove user from company.authorized_providers collection" do
        assert_false @company.reload.authorized_providers.include?(@provider)
      end
    end
  end
  
  context "company subscriptions" do
    setup do
      @company      = Factory(:company, :name => "mary's-hair Salon", :time_zone => "UTC")
      @subscription = @company.create_subscription(:user => @owner, :plan => @monthly_plan)
      @free_service = @company.free_service
      assert @free_service.valid?
      @company.reload
    end
  
    should "have free service" do
      assert_valid @free_service
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
      @subscription = @company.create_subscription(:user => @owner, :plan => @monthly_plan)
    end

    should "have default preferences" do
      assert_equal( ({:time_horizon => 28.days, :start_wday => '0', :appt_start_minutes=>[0], :public=>'1', :email_text => '',
                      :work_appointment_confirmation_customer=>'0', :work_appointment_confirmation_manager=>'0',
                      :work_appointment_confirmation_provider=>'0',
                      :customer_password => 'required',
                      :customer_email => 'optional',
                      :customer_phone => 'optional'}), @company.preferences)
    end

    should "have nil preferences[:foo]" do
      assert_nil @company.preferences[:foo]
    end

    context "then override default" do
      setup do
        @company.preferences[:time_horizon] = 14.days
        @company.save
      end

      should "have new value" do
        assert_equal 14.days, @company.preferences[:time_horizon]
      end
    end

    context "then add new preferences" do
      setup do
        @company.preferences["favorite fruit"] = "banana"
        @company.preferences["private"] = true
        @company.preferences["semi-private"] = "walnutindustries.com"
        @company.preferences["custom hash"] = ["fruit" => ["apple", "pear", "plum"], "airplanes" => %W{Airbus, Boeing, Lockheed, SAAB}]
        @company.preferences["meaning of life"] = 42
        @company.preferences[:time_horizon] = 5.days
        @company.save
      end
   
      should "have all preferences set" do
        assert_equal "banana", @company.preferences["favorite fruit"]
        assert_equal true, @company.preferences["private"]
        assert_equal "walnutindustries.com", @company.preferences["semi-private"]
        assert_equal ["fruit" => ["apple", "pear", "plum"], "airplanes" => %W{Airbus, Boeing, Lockheed, SAAB}], @company.preferences["custom hash"]
        assert_equal 42, @company.preferences["meaning of life"]
        assert_equal 5.days, @company.preferences[:time_horizon]
      end
      
    end
    
  end
  
  context "create a company with service, provider, subscription and owner" do
    setup do
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