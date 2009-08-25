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
        @haircut = Factory(:work_service, :name => "Haircut", :price => 10.00)
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

      context "then remove company" do
        setup do
          @company.destroy
        end

        should "have no Companies or CompanyServices" do
          assert_equal 0, Company.count
          assert_equal 0, CompanyService.count
        end
      end

    end
  end
  
  context "company providers" do
    setup do
      @company = Factory(:company, :name => "mary's-hair Salon", :time_zone => "UTC")
      @user1   = Factory(:user, :name => "Provider")
      assert_valid @user1
      @company.providers.push(@user1)
      @company.reload
    end
  
    should_change("CompanyProvider.count", :by => 1) { CompanyProvider.count }
    
    should "have company providers == [@user1]" do
      assert_equal [@user1], @company.providers
    end
    
    should "increment providers_count to 1" do
      assert_equal 1, @company.providers_count
    end

    should "have company.has_provider?(user) return true" do
      assert @company.has_provider?(@user1)
    end

    should "assign role 'company provider' on company to user" do
      assert_equal ['company provider'], @user1.roles_on(@company).collect(&:name)
    end
    
    context "and try to add the same provider" do
      setup do
        @company.providers.push(@user1)
        @company.reload
      end

      should_not_change("CompanyProvider.count") { CompanyProvider.count }

      should "have company providers == [@user1]" do
        assert_equal [@user1], @company.providers
      end
    end
    
    context "and then remove the user provider" do
      setup do
        @company.providers.delete(@user1)
        @company.reload
        @user1.reload
      end

      should "have no company providers" do
        assert_equal [], @company.providers
      end

      should "decrement providers_count to 0" do
        assert_equal 0, @company.providers_count
      end

      should "have company.has_provider?(user) return false" do
        assert !@company.has_provider?(@user1)
      end

      should "remove role 'company provider' on company from user" do
        assert_equal [], @user1.roles_on(@company).collect(&:name)
      end
    end
    
    context "then remove company" do
      setup do
        @company.destroy
      end

      should "have no Companies or CompanyProviders" do
        assert_equal 0, Company.count
        assert_equal 0, CompanyProvider.count
      end
    end
  end

  context "company subscriptions" do
    setup do
      @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
      @company      = Factory(:company, :name => "mary's-hair Salon", :time_zone => "UTC", :subscription => @subscription)
    end

    should "have free service" do
      assert @company.free_service
    end
    
    should "have services_count == 1" do
      assert_equal 1, @company.reload.services_count
    end

    should "have work_services_count == 0" do
      assert_equal 0, @company.work_services_count
    end

    context "then remove company" do
      setup do
        @company.destroy
      end

      should "have no Companies or Subscriptions" do
        assert_equal 0, Company.count
        assert_equal 0, Subscription.count
      end
    end
  end
  
  context "company with no preferences" do
    setup do
      @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
      @company      = Factory(:company, :name => "mary's hair Salon", :time_zone => "UTC", :subscription => @subscription)
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

end