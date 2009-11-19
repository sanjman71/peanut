# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Required gems for test environment
config.gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
config.gem "thoughtbot-shoulda", :lib => "shoulda/rails", :source => "http://gems.github.com"
config.gem "webrat", :version => ">=0.4.4"
config.gem "mocha"

MAIN_HOST = "www.walnutcalendar.test" 

config.action_controller.session = {
  :session_key => '_peanut_session',
  :secret      => '36791ab51cc708c1cf0314576d5a6a5fb5b1ecf2c4eebf911eeed605b2b666ffd62f24a93ae99519c100543b0ee9195866cdf0e088a0f64add7dad04da09ccd7',
  :domain      => ".walnutcalendar.test"
}

# ActiveMerchange configuration, using the Braintree gateway
config.after_initialize do 
  ActiveMerchant::Billing::Base.mode = :test 
  
  Payment.gateway = ActiveMerchant::Billing::BogusGateway.new
end
