require 'test/test_helper'

class WaitlistTest < ActiveSupport::TestCase
  should_belong_to              :company
  should_belong_to              :service
  should_belong_to              :provider
  should_belong_to              :customer
  should_belong_to              :location

  should_validate_presence_of   :company_id
  should_validate_presence_of   :service_id
  should_validate_presence_of   :customer_id

  should_have_many              :waitlist_time_ranges

  def setup
    @company        = Factory(:company, :name => "My Company")
    @provider       = Factory(:user, :name => "Provider")
    @company.user_providers.push(@provider)
    @company.reload
    @work_service   = Factory.build(:work_service, :name => "Work service", :price => 1.00)
    @work_service.user_providers.push(@provider)
    @company.services.push(@work_service)
    @customer       = Factory(:user, :name => "Customer")
  end

  context "create" do
    context "with no time range attributes" do
      setup do
        @waitlist = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }

      should "add 'company customer' role on company to customer" do
        assert_equal ['company customer'], @customer.reload.roles_on(@company).collect(&:name).sort
      end
    end

    context "with time range attributes" do
      setup do
        wait_attrs  = [{:start_date => "10/01/2009", :end_date => "10/02/2009", :start_time => "0900", :end_time => "1100"}]
        # Note: Rails doesn't support this yet
        # @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer,
        #                                         :waitlist_time_ranges_attributes => wait_attrs)
        @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
        @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
      end

      should_change("waitlist count", :by => 1) { Waitlist.count }
      should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }

      should "add 'company customer' role on company to customer" do
        assert_equal ['company customer'], @customer.reload.roles_on(@company).collect(&:name).sort
      end
    end
  end
  
  context "past" do
    setup do
      # create waitlist with time range in the past
      past        = (Time.zone.now - 1.day).to_s(:appt_schedule_day)
      wait_attrs  = [{:start_date => past, :end_date => past, :start_time => "0900", :end_time => "1100"}]
      @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
      @time_range = @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
    end

    should_change("waitlist count", :by => 1) { Waitlist.count }
    should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }
    
    should "be in the past" do
      assert_equal @waitlist.waitlist_time_ranges, WaitlistTimeRange.past
    end
  end
  
  context "future" do
    setup do
      # create waitlist with time range in the future
      future      = (Time.zone.now + 1.day).to_s(:appt_schedule_day)
      wait_attrs  = [{:start_date => future, :end_date => future, :start_time => "0900", :end_time => "1100"}]
      @waitlist   = @company.waitlists.create(:service => @work_service, :provider => @provider, :customer => @customer)
      @time_range = @waitlist.update_attributes(:waitlist_time_ranges_attributes => wait_attrs)
    end
    
    should_change("waitlist count", :by => 1) { Waitlist.count }
    should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }
    
    should "not be in the past" do
      assert_equal [], WaitlistTimeRange.past
    end
  end
end