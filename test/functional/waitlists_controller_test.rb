require 'test/test_helper'

class WaitlistsControllerTest < ActionController::TestCase

  # show waitlist for a specific user by state
  should_route :get, '/users/1/waitlist/upcoming',  
               :controller => 'waitlists', :action => 'index', :provider_type => 'users', :provider_id => 1, :state => 'upcoming'
  # show waitlist for a specific user, no state
  should_route :get, '/users/1/waitlist', :controller => 'waitlists', :action => 'index', :provider_type => 'users', :provider_id => 1
  # show waitlist for anyone
  should_route :get, '/waitlists', :controller => 'waitlists', :action => 'index'

  # new waitlist appointment
  should_route :get, '/waitlist/users/1/services/5',
               :controller => 'waitlists', :action => 'new', :provider_type => 'users', :provider_id => 1, :service_id => 5

  # schedule a waitlist appointment for a specific provider, with a date range
  # should_route :get, 'book/wait/users/1/services/5/20090101..20090201',
  #              :controller => 'appointments', :action => 'new', :provider_type => 'users', :provider_id => 1, :service_id => 5, 
  #              :start_date => '20090101', :end_date => '20090201', :mark_as => 'wait'
  # should_route :post, 'book/wait/users/1/services/5/20090101..20090201',
  #              :controller => 'appointments', :action => 'create_wait', :provider_type => 'users', :provider_id => 1, :service_id => 5, 
  #              :start_date => '20090101', :end_date => '20090201', :mark_as => 'wait'  


  def setup
    # create company
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company      = Factory(:company, :subscription => @subscription)
    @owner.grant_role('company manager', @company)
    # create provider
    @johnny       = Factory(:user, :name => "Johnny")
    @company.user_providers.push(@johnny)
    @company.reload
    # create a work service, and assign johnny as a service provider
    @haircut      = Factory.build(:work_service, :duration => 30.minutes, :name => "Haircut", :price => 1.00)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    # create a customer
    @customer     = Factory(:user, :name => "Customer")
    # stub current company
    @controller.stubs(:current_company).returns(@company)
  end
  
  # context "new" do
  #   context "as anonymous user" do
  #     setup do
  #       # stub current user
  #       @controller.stubs(:current_user).returns(false)
  #       get :new, :service_id => @haircut.id, :provider_id => @johnny.id, :provider_type => 'users'
  #     end
  # 
  #     should_respond_with :success
  # 
  #     should "show rpx login" do
  #       assert_select 'div#rpx_login', true
  #     end
  # 
  #     should "not show date and time fields" do
  #       assert_select 'div#when', false
  #     end
  #   end
  #   
  #   context "as registered user" do
  #     setup do
  #       # stub current user
  #       @controller.stubs(:current_user).returns(@customer)
  #       get :new, :service_id => @haircut.id, :provider_id => @johnny.id, :provider_type => 'users'
  #     end
  # 
  #     should_respond_with :success
  # 
  #     should "not show rpx login" do
  #       assert_select 'div#rpx_login', false
  #     end
  # 
  #     should "show date and time fields" do
  #       assert_select 'div#when', true
  #     end
  #   end
  # 
  #   context "for 'anyone' provider" do
  #     context "as registered user" do
  #       setup do
  #         # stub current user
  #         @controller.stubs(:current_user).returns(@customer)
  #         get :new, :service_id => @haircut.id, :provider_id => 0, :provider_type => 'users'
  #       end
  # 
  #       should_respond_with :success
  # 
  #       should "not show rpx login" do
  #         assert_select 'div#rpx_login', false
  #       end
  # 
  #       should "show date and time fields" do
  #         assert_select 'div#when', true
  #       end
  #     end
  #   end
  # end

  context "create" do
    context "with no time range attributes" do
      setup do
        # stub current user
        @controller.stubs(:current_user).returns(nil)
        post :create, :waitlist => {:service_id => @haircut.id, :provider_type => 'users', :provider_id => @johnny.id, :customer_id => @customer.id}
      end
  
      should_redirect_to("openings path") { openings_path }
      should_change("waitlist.count", :by => 1) { Waitlist.count }
      should_not_change("waitlist time range count") { WaitlistTimeRange.count }
    end

    context "with time range attributes" do
      setup do
        # stub current user
        @controller.stubs(:current_user).returns(nil)
        wait_attrs  = {"0" => {:start_date => "10/01/2009", :end_date => "10/02/2009", :start_time => "0900", :end_time => "1100"}}
        post :create, :waitlist => {:service_id => @haircut.id, :provider_type => 'users', :provider_id => @johnny.id, :customer_id => @customer.id,
                                    :waitlist_time_ranges_attributes => wait_attrs}
      end

      should_redirect_to("openings path") { openings_path }
      should_change("waitlist.count", :by => 1) { Waitlist.count }
      should_change("waitlist time range count", :by => 1) { WaitlistTimeRange.count }
    end
  end
  
end