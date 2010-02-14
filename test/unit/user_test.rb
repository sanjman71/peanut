require 'test/test_helper'

class UserTest < ActiveSupport::TestCase

  should_have_many    :subscriptions
  should_have_many    :plans, :through => :subscriptions
  should_have_many    :appointments

  context "user with no preferences" do
    setup do
      @user = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secret")
    end
    
    should "have default preferences" do
      assert_equal Hash[:provider_email_text => '', :provider_email_daily_schedule => '0'], @user.preferences
    end

    should "have nil preferences['foo']" do
      assert_nil @user.preferences['foo']
    end

    context "then add preferences" do
      setup do
        @user.preferences["favorite fruit"] = "banana"
        @user.preferences["private"] = true
        @user.preferences["semi-private"] = "walnutindustries.com"
        @user.preferences["custom hash"] = ["fruit" => ["apple", "pear", "plum"], "airplanes" => %W{Airbus, Boeing, Lockheed, SAAB}]
        @user.preferences["meaning of life"] = 42
      end

      should "have all preferences set" do
        assert_equal "banana", @user.preferences["favorite fruit"]
        assert_equal true, @user.preferences["private"]
        assert_equal "walnutindustries.com", @user.preferences["semi-private"]
        assert_equal ["fruit" => ["apple", "pear", "plum"], "airplanes" => %W{Airbus, Boeing, Lockheed, SAAB}], @user.preferences["custom hash"]
        assert_equal 42, @user.preferences["meaning of life"]
      end
    end
  end

end
