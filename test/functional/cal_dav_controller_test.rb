require 'test/test_helper'
require 'test/factories'

class CalDavControllerTest < ActionController::TestCase
  # There seems to be a bug working with the route recognition
  # I got this far in breakpointing before moving on
  # /opt/local/lib/ruby/gems/1.8/gems/actionpack-2.3.2/lib/action_controller/assertions/routing_assertions.rb:141
  # /opt/local/lib/ruby/gems/1.8/gems/actionpack-2.3.2/lib/action_controller/routing/recognition_optimisation.rb:56
  # should_route :get,  '/caldav', :controller => 'cal_dav', :action => 'webdav', :path_info => ""
  
  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @controller   = CalDavController.new
    # create a valid company
    @owner        = User.create(:name => "Owner", :email => "owner@walnutindustries.com",
                                :password => "secret", :password_confirmation => "secret",
                                :phone => "415 555 1234", :state => "active")
    @owner_token  = @owner.cal_dav_token
    
    @provider     = User.create(:name => "Provider", :email => "provider@walnutindustries.com",
                                :password => "secret", :password_confirmation => "secret",
                                :phone => "415 555 1234", :state => "active")
    @provider_token = @provider.cal_dav_token
    
    @user         = User.create(:name => "User", :email => "user@walnutindustries.com",
                                :password => "secret", :password_confirmation => "secret",
                                :phone => "415 555 1234", :state => "active")
    @user_token   = @user.cal_dav_token

    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)

    @company      = Factory(:company, :subscription => @subscription)

    @us           = Factory(:us)
    @il           = Factory(:il, :country => @us)
    @chicago      = Factory(:chicago, :state => @il)
    @zip          = Factory(:zip, :state => @il)
    @location     = Factory(:location, :city => @chicago, :state => @il, :country => @us, :zip => @zip)

    @company.locations.push(@location)

    # add providers
    @company.providers.push(@owner)
    @company.providers.push(@provider)

    # stub current company methods
    @controller.stubs(:current_company).returns(@company)
    ActionView::Base.any_instance.stubs(:current_company).returns(@company)

  end
  
  context "without company role (and no 'read calendar' privilege)" do
    setup do
    end

    context "get company calendar" do
      setup do
        get :webdav, :path_info => ["#{@user_token}"]
      end

      should_respond_with :forbidden
    end
    
    context "get provider calendar" do
      setup do
        get :webdav, :path_info => ["provider/#{@provider.id.to_s}/#{@user_token}"]
      end
      
      should_respond_with :forbidden
    end

    context "get location calendar" do
      setup do
        get :webdav, :path_info => ["location/#{@location.id.to_s}/#{@user_token}"]
      end
      
      should_respond_with :forbidden
    end

  end
  
  context "with 'company manager' role (includes 'read calendar' privilege)" do
    setup do
      # make owner the manager of company
      @owner.grant_role('company manager', @company)
    end

    context "get company calendar" do
      setup do
        get :webdav, :path_info => ["#{@owner_token}"]
      end

      should_respond_with :success
    end
    
    context "get provider calendar" do
      setup do
        get :webdav, :path_info => ["provider/#{@provider.id.to_s}/#{@owner_token}"]
      end
      
      should_respond_with :success
    end

    context "get location calendar" do
      setup do
        get :webdav, :path_info => ["location/#{@location.id.to_s}/#{@owner_token}"]
      end
      
      should_respond_with :success
    end

  end

end
