require 'test_helper'

class OpeningsControllerTest < ActionController::TestCase

  context "routes" do
    # basic index and reschedule paths
    should route(:get, '/openings').to(:controller => 'openings', :action => 'index')
    # should route(:get, '/openings/reschedule').to(:controller => 'openings', :action => 'index', :type => 'reschedule')
  
    # search appointments for a specified provider, duration and service, with a when range
    should route(:post, '/users/1/services/3/2700/openings/this-week/anytime').to(
                 :controller => 'openings', :action => 'index', :provider_type => 'users', :provider_id => 1,
                 :service_id => 3, :duration => 45.minutes, :when => 'this-week', :time => 'anytime')

    # search appointments for a specified provider, duration and service, with a date range
    should route(:post, '/users/1/services/3/2700/openings/20090101..20090201/anytime').to(
                 :controller => 'openings', :action => 'index', :provider_type => 'users', :provider_id => 1, :service_id => 3,
                 :duration => 45.minutes, :start_date => '20090101', :end_date => '20090201', :time => 'anytime')

    # search appointments for a specified provider, duration and service, with a date
    should route(:post, '/users/1/services/3/2700/openings/20090101/anytime').to(
                 :controller => 'openings', :action => 'index', :provider_type => 'users', :provider_id => 1, :service_id => 3,
                 :duration => 45.minutes, :start_date => '20090101', :time => 'anytime')

    # search appointments for anyone providing a specified service with duration, with a when range
    should route(:post, '/services/3/7200/openings/this-week/anytime').to(
                 :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120.minutes,
                 :when => 'this-week', :time => 'anytime')

    # search appointments for anyone providing a specified service with duration, with a date range
    should route(:post, '/services/3/7200/openings/20090101..20090201/anytime').to(
                 :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120.minutes,
                 :start_date => '20090101', :end_date => '20090201', :time => 'anytime')

     # search appointments for anyone providing a specified service with duration, with a date
     should route(:post, '/services/3/7200/openings/20090101/anytime').to(
                  :controller => 'openings', :action => 'index', :service_id => 3, :duration => 120.minutes,
                  :start_date => '20090101', :time => 'anytime')
  end

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
    @company.reload
    # stub current company method for the controller and the view
    @controller.stubs(:current_company).returns(@company)
    # stub current location to anywhere
    @controller.stubs(:current_location).returns(Location.anywhere)
    @controller.stubs(:current_locations).returns([])
    # set host
    @request.host = "www.test.host"
  end
  
  context "search" do
    context "specific service, specific provider, anytime" do
      setup do
        post :search, :service_id => @haircut.id, :duration => 90.minutes, :provider => "users/#{@johnny.id}",
                      :when => 'this-week', :time => 'anytime'
      end

      should "redirect" do
        assert_redirected_to("/users/#{@johnny.id}/services/#{@haircut.id}/5400/openings/this-week/anytime")
      end
    end

    context "specific service, any provider, this week, anytime" do
      setup do
        post :search, :service_id => @haircut.id, :duration => 90.minutes, :provider => "0",
                      :when => 'this-week', :time => 'anytime'
      end

      should "redirect" do
        assert_redirected_to("/services/#{@haircut.id}/5400/openings/this-week/anytime")
      end
    end

    context "specific service, any provider, specific date, anytime" do
      setup do
        post :search, :service_id => @haircut.id, :duration => 90.minutes, :provider => "0",
                      :start_date => '20100101', :time => 'anytime'
      end

      should "redirect" do
        assert_redirected_to("/services/#{@haircut.id}/5400/openings/20100101/anytime")
      end
    end

    context "specific service, no provider, this week, anytime" do
      setup do
        post :search, :service_id => @haircut.id, :duration => 90.minutes, :when => 'this-week', :time => 'anytime'
      end

      should "redirect" do
        assert_redirected_to("/services/#{@haircut.id}/5400/openings/this-week/anytime")
      end
    end
  end

  fast_context "index" do
    fast_context "with an invalid service" do
      setup do
        get :index, :service_id => -1
      end

      should redirect_to("openings_path") { openings_path }
    end

    fast_context "with a valid service, but invalid duration" do
      setup do
        # create company service that does not allow a custom duration
        get :index, :service_id => @haircut.id, :duration => 90.minutes, :when => 'this-week', :time => 'anytime'
      end

      should redirect_to("openings services path with default duration value") { "/services/#{@haircut.id}/1800/openings/this-week/anytime" }
    end

    fast_context "with specified 'anyone' provider" do
      setup do
        get :index, :provider_id => '0'
      end

      should redirect_to("openings_path") { openings_path }
    end

    fast_context "with specified 'any' service" do
      setup do
        get :index, :service_id => '0'
      end

      should redirect_to("openings_path") { openings_path }
    end

    fast_context "as customer in data_missing state" do
      setup do
        @user = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secret", :preferences_email => 'required')
        assert_equal 'data_missing', @user.state
        @user.grant_role('company customer', @company)
        @controller.stubs(:current_user).returns(@user)
        get :index
      end

      should "set session[:return_to]" do
        assert_equal "/openings", session[:return_to]
      end

      should redirect_to("user edit path") { "/users/#{@user.id}/edit" }
    end

    fast_context "for a private company" do
      fast_context "as a guest" do
        setup do
          # private company
          @company.preferences[:public] = 0
          @company.save
          get :index
        end

        should_not assign_to(:daterange)
        should assign_to(:public) { 0 }
        should assign_to(:searchable) { false }
        should_not assign_to(:customer)
        should_not assign_to(:waitlist)

        should "not have 'add waitlist' link" do
          assert_select "a#add_waitlist", 0
        end

        should respond_with :success
        should render_template 'openings/index.html.haml'
      end

      fast_context "as company manager" do
        setup do
          # private company
          @company.preferences[:public] = 0
          @company.save
          @controller.stubs(:current_user).returns(@owner)
          get :index
        end

        should_not assign_to(:daterange)
        should assign_to(:public) { 0 }
        should assign_to(:searchable) { true }
        should_not assign_to(:customer)
        should_not assign_to(:waitlist)

        should respond_with :success
        should render_template 'openings/index.html.haml'
      end
    end

    fast_context "with no service and no provider" do
      setup do
        get :index
      end

      should "have 'nothing' service" do
        assert_true assigns(:service).nothing?
      end

      should "have 'anyone' user" do
        assert_true assigns(:provider).anyone?
      end

      should_not assign_to(:daterange)
      should assign_to(:duration) { 0 }
      should assign_to(:searchable) { true }
      should_not assign_to(:customer)
      should_not assign_to(:waitlist)

      should "set services collection" do
        assert_equal ['Select a service', 'Haircut'], assigns(:services).collect(&:name)
      end

      should respond_with :success
      should render_template 'openings/index.html.haml'
    end

    fast_context "with a specific service and any provider" do
      fast_context "as guest" do
        setup do
          get :index, :service_id => @haircut.id, :duration => @haircut.duration, :when => 'this-week', :time => 'anytime'
        end

        should assign_to(:service) { @haircut}

        should "have 'anyone' user" do
          assert_true assigns(:provider).anyone?
        end

        should assign_to(:daterange)
        should assign_to(:duration) { 30 * 60 }
        should assign_to(:searchable) { true }
        should_not assign_to(:customer)
        should_not assign_to(:waitlist)

        should "have 'add waitlist' link" do
          assert_select "a#add_waitlist", 1
        end

        should "set services collection" do
          assert_equal ['Select a service', 'Haircut'], assigns(:services).collect(&:name)
        end

        should respond_with :success
        should render_template 'openings/index.html.haml'

        should "have rpx login dialog" do
          assert_select "div#rpx_login_dialog", 1
        end

        should "not have confirm appointment dialog" do
          assert_select "div#confirm_appointment_dialog", 0
        end

        should "not have add waitlist dialog" do
          assert_select "div#add_waitlist_dialog", 0
        end

        should "have service select list with 1 service" do
          assert_select "select.openings.search.wide#service_id", 1
          assert_select "select.openings.search.wide#service_id" do
            assert_select "option[value='#{@haircut.id}']", {:text => 'Haircut'}
          end
        end

        should "have provider select list with 2 providers'" do
          assert_select "select.openings.search.wide#provider", 1
          assert_select "select.openings.search.wide#provider option", 2
          assert_select "select.openings.search.wide#provider" do
            assert_select "option[value='users/#{@johnny.id}']", {:text => 'Johnny'}
            assert_select "option[value='users/#{@peter.id}']", {:text => 'Peter'}
          end
        end

        should "have no available capacity slots" do
          assert_select "div#free_capacity_slots div.slots", 0
        end
      end
      
      fast_context "as company manager" do
        setup do
          @controller.stubs(:current_user).returns(@owner)
          get :index, :service_id => @haircut.id, :duration => @haircut.duration, :when => 'this-week', :time => 'anytime'
        end

        should assign_to(:service) { @haircut}

        should "have 'anyone' user" do
          assert_true assigns(:provider).anyone?
        end

        should assign_to(:daterange)
        should assign_to(:duration) { 30 * 60 }
        should assign_to(:searchable) { true }
        should assign_to(:customer) { @owner }
        should assign_to(:waitlist)

        should "have 'add waitlist' link" do
          assert_select "a#add_waitlist", 1
        end

        should "set services collection" do
          assert_equal ['Select a service', 'Haircut'], assigns(:services).collect(&:name)
        end

        should respond_with :success
        should render_template 'openings/index.html.haml'

        should "not have rpx login dialog" do
          assert_select "div#rpx_login_dialog", 0
        end

        should "have confirm appointment dialog" do
          assert_select "div#confirm_appointment_dialog", 1
        end

        should "have add waitlist dialog" do
          assert_select "div#add_waitlist_dialog", 1
        end

        should "have service select list with 1 service" do
          assert_select "select.openings.search.wide#service_id", 1
          assert_select "select.openings.search.wide#service_id" do
            assert_select "option[value='#{@haircut.id}']", {:text => 'Haircut'}
          end
        end

        should "have provider select list with 2 providers'" do
          assert_select "select.openings.search.wide#provider", 1
          assert_select "select.openings.search.wide#provider option", 2
          assert_select "select.openings.search.wide#provider" do
            assert_select "option[value='users/#{@johnny.id}']", {:text => 'Johnny'}
            assert_select "option[value='users/#{@peter.id}']", {:text => 'Peter'}
          end
        end

        should "have no available capacity slots" do
          assert_select "div#free_capacity_slots div.slots", 0
        end
      end
    end
  end

end
