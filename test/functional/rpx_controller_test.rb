require 'test/test_helper'

class RpxControllerTest < ActionController::TestCase

  should_route :get,  '/rpx/customer', :controller => 'rpx', :action => 'customer'

  context "rpx customer" do
    context "create customer using rpx token" do
      setup do
        # stub RPXNow
        @rpx_hash = {:name=>'sanjman71',:email=>'sanjman71@gmail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
        RPXNow.stubs(:user_data).returns(@rpx_hash)
        get :customer, :token => '12345'
      end

      should_change("User.count", :by => 1) { User.count }

      should_assign_to :data
      
      should "assign user identifier" do
        @user = User.find_by_email("sanjman71@gmail.com")
        assert_equal 'https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM', @user.identifier
      end
    end
    
    # context "login using rpx token" do
    # end
  end
end