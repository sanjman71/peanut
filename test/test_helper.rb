ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'mocha'
require 'factories'
require 'fast_context'

include AuthenticatedTestHelper
include AuthenticatedSystem

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  
  # ActiveMerchant testing helpers
  include ActiveMerchant::Billing
  
  def credit_card_hash(options = {}) 
    { :number     => '1', 
      :first_name => 'Cody', 
      :last_name  => 'Fauser', 
      :month      => '8', 
      :year       => "#{ Time.now.year + 1 }", 
      :verification_value => '123', 
      :type       => 'visa' 
    }.update(options) 
  end
  
  def credit_card(options = {}) 
    ActiveMerchant::Billing::CreditCard.new(credit_card_hash(options)) 
  end
  
  def billing_address(options = {}) 
    { :name     => 'Cody Fauser', 
      :address1 => '2500 Oak Mills Road', 
      :address2 => 'Suite 1000', 
      :city     => 'Beverly Hills', 
      :state    => 'CA', 
      :country  => 'US', 
      :zip      => '90210' 
    }.update(options) 
  end

  def assert_true(x)
    assert(x)
  end
  
  def assert_false(x)
    assert(!x)
  end
  
  def assert_not_valid(x)
    assert !x.valid?
  end  

  def assert_nil(x)
    assert_equal nil, x
  end

  DAYS_OF_WEEK = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU']
  
  def ical_days(days)
    a = []
    days.each do |day|
      a << DAYS_OF_WEEK[day.wday - 1]
    end
    a.join(',')
  end

  def work_off_delayed_jobs
    @worker ||= Delayed::Worker.new(:quiet => true)
    @worker.work_off(Delayed::Job.count)
  end

  def add_mary_and_johnny_as_providers
    # add johnny as a company provider
    @johnny = Factory(:user, :name => "Johnny")
    @company.user_providers.push(@johnny)
    @johnny.reload
    @company.reload
    @mary = Factory(:user, :name => "Mary")
    @company.user_providers.push(@mary)
    @mary.reload
    @company.reload
    # create a work service, and assign johnny and mary as service providers
    @haircut = Factory.build(:work_service, :duration => 30.minutes, :name => "Haircut", :price => 1.00)
    @company.services.push(@haircut)
    @haircut.user_providers.push(@johnny)
    @haircut.user_providers.push(@mary)
  end

end

class ActionView::Base
  include ApplicationHelper
  include AuthenticatedSystem
end

Webrat.configure do |config|
  config.mode = :rails
end
