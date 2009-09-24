require 'test/test_helper'

class SignupTest < ActionController::IntegrationTest

  def setup
    @indy_plan = Factory(:monthly_plan, :name => "Indy", :cost => 500)
    assert @indy_plan.valid?
  end
  
  test "signing up as a new user for the indy plan" do
    visit signup_plan_path(:plan_id => @indy_plan.id)

    # user info
    fill_in "user_name", :with => "Sanjay"
    # fill_in "user_email_addresses_attributes_address", :with => "sanjay@jarna.com"
    fill_in "user_password", :with => "secret"  
    fill_in "user_password_confirmation", :with => "secret"  
    
    # company info
    fill_in "company_name", :with => "Widgets R Us"
    fill_in "company_subdomain", :with => "widgetsrus"
    fill_in "company_time_zone", :with => "Central Time (US & Canada)"
    
    # billing info
    fill_in "cc_first_name", :with => "Sanjay"
    fill_in "cc_last_name", :with => "Kapoor"
    fill_in "cc_type", :with => "master"
    fill_in "cc_number", :with => "1"  # in test environment, 1 is always valid
    fill_in "cc_month", :with => "2"
    fill_in "cc_year", :with => "2013"
    fill_in "cc_verification_value", :with => "123"

    # terms and conditions
    fill_in "company_terms", :with => "1"
    
    # post form
    click_button "Sign Up"
    assert_response :success
    assert_not_nil Company.find_by_subdomain("widgetsrus")
  end
  
end
