require 'test_helper'

class OpeningsTest < ActionController::IntegrationTest

  def setup
    Company.delete_all
    Service.delete_all
    # create a valid company, with 1 service and 2 providers
    @owner        = Factory(:user, :name => "Owner", :password => 'secret')
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription, :name => 'Widgets Co', :subdomain => 'widgetsco')
    # activate company
    @company.subscription.authorized!
    @company.subscription.active!
    @owner.grant_role('company manager', @company)
    @johnny       = Factory(:user, :name => "Johnny")
    @company.user_providers.push(@johnny)
    @peter        = Factory(:user, :name => "Peter")
    @company.user_providers.push(@peter)
    @haircut      = Factory.build(:work_service, :name => "Haircut", :price => 10.00, :duration => 30.minutes)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    @haircut.user_providers.push(@peter)
  end

  test "openings index page as guest" do
    visit openings_url(:subdomain => @company.subdomain)
    assert_response :success
    assert_have_selector "head title:contains('Schedule an Appointment | #{@company.name}')"

    # fill out openings search
    # select 'Haircut', :from => "service_id"
    # select 'next week', :from => "when"
    # click_link "search_submit"
    # assert_response :success

    # search openings, with specific service and any provider
    visit openings_anyone_when_url(:service_id => @haircut.id, :duration => @haircut.duration, :when => 'next-week', :time => 'anytime', :subdomain => @company.subdomain)
    assert_response :success
    assert_have_selector "div#free_calendar"
    assert_have_selector "div#free_capacity_slots"
    assert_have_no_selector "div#free_capacity_slots div.slots"
    assert_have_selector "div#rpx_login_dialog"
  end
  
end