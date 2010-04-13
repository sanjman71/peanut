require 'test/test_helper'

class CapacitySlotsControllerTest < ActionController::TestCase

  # SK: not sure why this generates an error
  # should_route :get, '/users/1/capacity/20100101T090000..20100101T120000',
  #                    :controller => 'capacity_slots', :action => 'capacity', :provider_type => 'users', :provider_id => '1'

  def setup
    # create a valid company, with 1 service and 2 providers
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    @johnny       = Factory(:user, :name => "Johnny")
    @company.user_providers.push(@johnny)
    @peter        = Factory(:user, :name => "Peter")
    @company.user_providers.push(@peter)
    @haircut      = Factory.build(:work_service, :name => "Haircut", :price => 10.00, :duration => 30.minutes)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    @haircut.user_providers.push(@peter)
    # stub current company method for the controller and the view
    @controller.stubs(:current_company).returns(@company)
    # stub current location to anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    @controller.stubs(:current_locations).returns([])
    @start_tomorrow = Time.zone.now.tomorrow.beginning_of_day
  end

  context "capacity" do
    context "with capacity slot of 1 around" do
      setup do
        @slot = CapacitySlot.create(:company => @company, :provider => @johnny, :capacity => 1,
                                    :start_at => @start_tomorrow, :end_at => @start_tomorrow + 8.hours)
        xhr :get, :capacity, :format => 'json', :provider_type => 'users', :provider_id => @johnny.id,
                  :start_time => @start_tomorrow.to_s(:appt_schedule), :end_time => (@start_tomorrow+1.hour).to_s(:appt_schedule)
      end

      should_assign_to(:provider) { @provider}

      should_respond_with_content_type "application/json"

      should "send json response with provider capacity" do
        @json = JSON.parse(@response.body)
        assert_equal Hash["capacity" => 1], @json
      end
    end

    context "with capacity slot of 1 inside" do
      setup do
        @slot = CapacitySlot.create(:company => @company, :provider => @johnny, :capacity => 1,
                                    :start_at => @start_tomorrow, :end_at => @start_tomorrow + 1.hours)
        xhr :get, :capacity, :format => 'json', :provider_type => 'users', :provider_id => @johnny.id,
                  :start_time => @start_tomorrow.to_s(:appt_schedule), :end_time => (@start_tomorrow+2.hours).to_s(:appt_schedule)
      end

      should_assign_to(:provider) { @provider}

      should_respond_with_content_type "application/json"

      should "send json response with provider capacity" do
        @json = JSON.parse(@response.body)
        assert_equal Hash["capacity" => 1], @json
      end
    end

    context "with capacity slot of 1 overlapping" do
      setup do
        @slot = CapacitySlot.create(:company => @company, :provider => @johnny, :capacity => 1,
                                    :start_at => @start_tomorrow, :end_at => @start_tomorrow + 1.hour)
        xhr :get, :capacity, :format => 'json', :provider_type => 'users', :provider_id => @johnny.id,
                  :start_time => (@start_tomorrow-1.hour).to_s(:appt_schedule), :end_time => (@start_tomorrow+1.hour).to_s(:appt_schedule)
      end

      should_assign_to(:provider) { @provider}

      should_respond_with_content_type "application/json"

      should "send json response with provider capacity" do
        @json = JSON.parse(@response.body)
        assert_equal Hash["capacity" => 1], @json
      end
    end

    context "with capacity slot of 1 not overlapping" do
      setup do
        @slot = CapacitySlot.create(:company => @company, :provider => @johnny, :capacity => 1,
                                    :start_at => @start_tomorrow, :end_at => @start_tomorrow + 1.hour)
        xhr :get, :capacity, :format => 'json', :provider_type => 'users', :provider_id => @johnny.id,
                  :start_time => (@start_tomorrow+1.hour).to_s(:appt_schedule), :end_time => (@start_tomorrow+3.hours).to_s(:appt_schedule)
      end

      should_assign_to(:provider) { @provider}

      should_respond_with_content_type "application/json"

      should "send json response with provider capacity" do
        @json = JSON.parse(@response.body)
        assert_equal Hash["capacity" => 0], @json
      end
    end
  end

end