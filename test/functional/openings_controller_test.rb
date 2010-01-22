require 'test/test_helper'

class OpeningsControllerTest < ActionController::TestCase

  # basic index and reschedule paths
  should_route :get, '/openings', :controller => 'openings', :action => 'index'
  should_route :get, '/openings/reschedule', :controller => 'openings', :action => 'index', :type => 'reschedule'
  
  # search appointments for a specified provider, duration and service, with a when range
  should_route :post, '/users/1/services/3/2700/openings/this-week/anytime',
               :controller => 'openings', :action => 'index', :provider_type => 'users', :provider_id => 1, :service_id => 3, 
               :duration => 45.minutes, :when => 'this-week', :time => 'anytime'

  # search appointments for a specified provider, duration and service, with a date range
  should_route :post, '/users/1/services/3/2700/openings/20090101..20090201/anytime',
               :controller => 'openings', :action => 'index', :provider_type => 'users', :provider_id => 1, :service_id => 3, 
               :duration => 45.minutes, :start_date => '20090101', :end_date => '20090201', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration, with a when range
  should_route :post, '/services/3/7200/openings/this-week/anytime',
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120.minutes, :when => 'this-week', :time => 'anytime'

  # search appointments for anyone providing a specified service with a specified service duration, with a date range
  should_route :post, '/services/3/7200/openings/20090101..20090201/anytime',
               :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120.minutes, 
               :start_date => '20090101', :end_date => '20090201', :time => 'anytime'

  def setup
    # create a valid company, with 1 provider and 1 work service
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    @johnny       = Factory(:user, :name => "Johnny")
    @company.user_providers.push(@johnny)
    @haircut      = Factory.build(:work_service, :name => "Haircut", :price => 10.00, :duration => 30.minutes)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    @company.reload
    # stub current company method for the controller and the view
    @controller.stubs(:current_company).returns(@company)
    # stub current location to anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    @controller.stubs(:current_locations).returns([])
    # Set the request hostname
    # @request.host = "www.peanut.com"
  end
  
  context "search" do
    context "specific service, specific provider, anytime" do
      setup do
        post :search, :service_id => @haircut.id, :duration => 90.minutes, :provider => "users/#{@johnny.id}", :when => 'this-week', :time => 'anytime'
      end

      should_redirect_to("index path, with service and provider") { "/users/#{@johnny.id}/services/#{@haircut.id}/5400/openings/this-week/anytime" }
    end

    context "specific service, any provider, anytime" do
      setup do
        post :search, :service_id => @haircut.id, :duration => 90.minutes, :provider => "0", :when => 'this-week', :time => 'anytime'
      end

      should_redirect_to("index path, with service and no provider") { "/services/#{@haircut.id}/5400/openings/this-week/anytime" }
    end

    context "specific service, no provider, anytime" do
      setup do
        post :search, :service_id => @haircut.id, :duration => 90.minutes, :when => 'this-week', :time => 'anytime'
      end

      should_redirect_to("index path, with service and no provider") { "/services/#{@haircut.id}/5400/openings/this-week/anytime" }
    end
  end

  context "index" do
    context "with an invalid service" do
      setup do
        get :index, :service_id => -1
      end

      should_redirect_to("openings_path") { openings_path }
    end

    context "with a valid service, but invalid duration" do
      setup do
        # create company service that does not allow a custom duration
        get :index, :service_id => @haircut.id, :duration => 90.minutes, :when => 'this-week', :time => 'anytime'
      end

      should_redirect_to("openings services path with default duration value") { "/services/#{@haircut.id}/1800/openings/this-week/anytime" }
    end

    context "with specified 'anyone' provider" do
      setup do
        get :index, :provider_id => '0'
      end

      should_redirect_to("openings_path") { openings_path }
    end

    context "with specified 'any' service" do
      setup do
        get :index, :service_id => '0'
      end

      should_redirect_to("openings_path") { openings_path }
    end

    context "for a private company" do
      context "as a guest" do
        setup do
          # private company
          @company.preferences[:public] = 0
          @company.save
          get :index
        end

        should_not_assign_to(:daterange)
        should_assign_to(:public) { 0 }
        should_assign_to(:searchable) { false }
        should_not_assign_to(:waitlist)

        should "not have 'add waitlist' link" do
          assert_select "a#add_waitlist", 0
        end

        should_respond_with :success
        should_render_template 'openings/index.html.haml'
      end

      context "as company manager" do
        setup do
          # private company
          @company.preferences[:public] = 0
          @company.save
          @controller.stubs(:current_user).returns(@owner)
          get :index
        end

        should_not_assign_to(:daterange)
        should_assign_to(:public) { 0 }
        should_assign_to(:searchable) { true }
        should_not_assign_to(:waitlist)

        should_respond_with :success
        should_render_template 'openings/index.html.haml'
      end
    end

    context "with no service and no provider" do
      setup do
        get :index
      end

      should "have 'nothing' service" do
        assert_true assigns(:service).nothing?
      end

      should "have 'anyone' user" do
        assert_true assigns(:provider).anyone?
      end

      should_not_assign_to(:daterange)
      should_assign_to(:duration) { 0 }
      should_assign_to(:searchable) { true }
      should_not_assign_to(:waitlist)

      should "set services collection" do
        assert_equal ['Select a service', 'Haircut'], assigns(:services).collect(&:name)
      end

      should_respond_with :success
      should_render_template 'openings/index.html.haml'
    end

    context "with a specific service" do
      context "as guest" do
        setup do
          get :index, :service_id => @haircut.id, :duration => @haircut.duration, :when => 'this-week', :time => 'anytime'
        end

        should_assign_to(:service) { @haircut}

        should "have 'anyone' user" do
          assert_true assigns(:provider).anyone?
        end

        should_assign_to(:daterange)
        should_assign_to(:duration) { 30 * 60 }
        should_assign_to(:searchable) { true }
        should_not_assign_to(:customer)
        should_not_assign_to(:waitlist)

        should "have 'add waitlist' link" do
          assert_select "a#add_waitlist", 1
        end

        should "set services collection" do
          assert_equal ['Select a service', 'Haircut'], assigns(:services).collect(&:name)
        end

        should "have rpx login dialog" do
          assert_select "div#rpx_login_dialog", 1
        end

        should "not have confirm appointment dialog" do
          assert_select "div#confirm_appointment_dialog", 0
        end
        
        should_respond_with :success
        should_render_template 'openings/index.html.haml'
      end
      
      context "as company manager" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          get :index, :service_id => @haircut.id, :duration => @haircut.duration, :when => 'this-week', :time => 'anytime'
        end

        should_assign_to(:service) { @haircut}

        should "have 'anyone' user" do
          assert_true assigns(:provider).anyone?
        end

        should_assign_to(:daterange)
        should_assign_to(:duration) { 30 * 60 }
        should_assign_to(:searchable) { true }
        should_assign_to(:customer) { @owner }
        should_assign_to(:waitlist)

        should "have 'add waitlist' link" do
          assert_select "a#add_waitlist", 1
        end

        should "set services collection" do
          assert_equal ['Select a service', 'Haircut'], assigns(:services).collect(&:name)
        end

        should "not have rpx login dialog" do
          assert_select "div#rpx_login_dialog", 0
        end

        should "have confirm appointment dialog" do
          assert_select "div#confirm_appointment_dialog", 1
        end

        should_respond_with :success
        should_render_template 'openings/index.html.haml'
      end
    end
  end

end
