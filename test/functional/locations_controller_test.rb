require 'test/test_helper'

class LocationsControllerTest < ActionController::TestCase

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    # create country, states
    @us = Country.create(:name => "United States", :code => "US")
    @il = State.create(:name => "Illinois", :code => "IL", :country => @us)
    # stub current company
    @controller.stubs(:current_company).returns(@company)
  end

  context "create" do
    context "with invalid city, state combination" do
      setup do
        @company.stubs(:may_add_location?).returns(true)
        post :create, :location => {:city => "San Francisco", :country_id => @us.id, :state_id => @il.id, :street_address => '200 W Grand Ave'}
      end

      should_not_change("locations count") { Location.count }

      should "have error on city" do
        assert_equal "San Francisco is not a valid city in Illinois", assigns(:location).errors.on(:city)
      end

      should_respond_with :success
      should_render_template 'locations/new.html.haml'
    end

    context "with invalid zip, state combination" do
      setup do
        @company.stubs(:may_add_location?).returns(true)
        post :create, :location => {:zip => "95070", :country_id => @us.id, :state_id => @il.id, :street_address => '200 W Grand Ave'}
      end
      
      should_not_change("locations count") { Location.count }

      should "have error on zip" do
        assert_equal "95070 is not a valid zip in Illinois", assigns(:location).errors.on(:zip)
      end

      should_respond_with :success
      should_render_template 'locations/new.html.haml'
    end
    
    context "with valid city, state combination" do
      setup do
        @company.stubs(:may_add_location?).returns(true)
        post :create, :location => {:city => "Chicago", :country_id => @us.id, :state_id => @il.id, :street_address => '200 W Grand Ave'}
      end

      should_change("locations count", :by => 1) { Location.count }

      should "change company locations count" do
        assert_equal 1, @company.reload.locations_count
      end

      should "create location with city" do
        @location = @company.locations.first
        assert_equal "Chicago", @location.city.name
      end

      should "create location with state" do
        @location = @company.locations.first
        assert_equal "Illinois", @location.state.name
      end

      should_redirect_to("company edit path") { "/edit" }
    end
    
    context "with valid city, state, zip combination" do
      setup do
        @company.stubs(:may_add_location?).returns(true)
        post :create, :location => {:city => "Chicago", :zip => "60654", :country_id => @us.id, :state_id => @il.id, :street_address => '200 W Grand Ave'}
      end
      
      should_change("locations count", :by => 1) { Location.count }

      should "change company locations count" do
        assert_equal 1, @company.reload.locations_count
      end
      
      should "create location with city" do
        @location = @company.locations.first
        assert_equal "Chicago", @location.city.name
      end

      should "create location with state" do
        @location = @company.locations.first
        assert_equal "Illinois", @location.state.name
      end

      should "create location with zip" do
        @location = @company.locations.first
        assert_equal "60654", @location.zip.name
      end

      should_redirect_to("company edit path") { "/edit" }
    end
  end

end