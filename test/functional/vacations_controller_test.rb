require 'test/test_helper'

class VacationsControllerTest < ActionController::TestCase

  # we support both company vacations and provider vacations
  should_route :get, '/vacations', :controller => 'vacations', :action => 'index'
  should_route :get, '/users/1/vacations',  :controller => 'vacations', :action => 'index', :provider_type => 'users', :provider_id => 1
  should_route :post, '/vacation', :controller => 'vacations', :action => 'create'
  should_route :post, '/users/1/vacation', :controller => 'vacations', :action => 'create', :provider_type => 'users', :provider_id => 1
  should_route :delete, '/vacation', :controller => 'vacations', :action => 'destroy'
  should_route :delete, '/users/1/vacation', :controller => 'vacations', :action => 'destroy', :provider_type => 'users', :provider_id => 1

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @owner_email  = @owner.email_addresses.create(:address => 'owner@walnutcalendar.com')
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    # add company providers
    @company.user_providers.push(@owner)
    # stub current company
    @controller.stubs(:current_company).returns(@company)
    # stub current location to be anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    # set the request hostname
    @request.host = "www.walnutcalendar.com"
  end

  context "index" do
    context "provider vacations" do
      setup do
        get :index, :provider_type => 'users', :provider_id => @owner.id
      end

      should_assign_to(:provider) { @owner }

      should_respond_with :success
      should_render_template 'vacations/index.html.haml'
    end

    context "company vacations" do
      setup do
        @start_at = Time.zone.parse("20100101").beginning_of_day
        @end_at   = Time.zone.parse("20100107").beginning_of_day
        @vacation = @company.appointments.create(:start_at => @start_at, :end_at => @end_at, :mark_as => 'vacation')
        assert @vacation.valid?
        get :index
      end

      should_not_assign_to(:provider)
      should_assign_to(:vacations) { [@vacation] }

      should_respond_with :success
      should_render_template 'vacations/index.html.haml'
    end
  end

  context "create" do
    context "provider vacation" do
      setup do
        post :create, :provider_type => 'users', :provider_id => @owner.id, :start_date => '20100101', :end_date => '20100108'
      end

      should_assign_to(:provider) { @owner }

      should_change("appointment vacation count", :by => 1) { Appointment.count }
    end

    context "company vacation" do
      setup do
        post :create, :start_date => '20100101', :end_date => '20100108'
      end

      should_not_assign_to(:provider)

      should_change("appointment vacation count", :by => 1) { Appointment.count }
    end
  end

  context "destroy" do
    context "provider vacation" do
      setup do
        @start_at = Time.zone.parse("20100101").beginning_of_day
        @end_at   = Time.zone.parse("20100107").beginning_of_day
        @vacation = @company.appointments.create(:provider => @owner, :start_at => @start_at, :end_at => @end_at, :mark_as => 'vacation')
        assert @vacation.valid?
        delete :destroy, :provider_type => 'users', :provider_id => @owner.id, :id => @vacation.id
      end

      should_assign_to(:provider) { @owner }
      should_assign_to(:vacation) { @vacation }

      should "delete vacation" do
        assert_nil Appointment.find_by_id(@vacation.id)
      end

      should_redirect_to("index path") { "/users/#{@owner.id}/vacations" }
    end

    context "company vacation" do
      setup do
        @start_at = Time.zone.parse("20100101").beginning_of_day
        @end_at   = Time.zone.parse("20100107").beginning_of_day
        @vacation = @company.appointments.create(:start_at => @start_at, :end_at => @end_at, :mark_as => 'vacation')
        assert @vacation.valid?
        delete :destroy, :id => @vacation.id
      end

      should_not_assign_to(:provider)
      should_assign_to(:vacation) { @vacation }

      should "delete vacation" do
        assert_nil Appointment.find_by_id(@vacation.id)
      end

      should_redirect_to("index path") { "/vacations" }
    end
  end

end