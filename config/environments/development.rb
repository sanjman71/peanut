# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

MAIN_HOST = "www.peanut.dev" 

config.action_controller.session = {
  :session_key => '_peanut_session',
  :secret      => '36791ab51cc708c1cf0314576d5a6a5fb5b1ecf2c4eebf911eeed605b2b666ffd62f24a93ae99519c100543b0ee9195866cdf0e088a0f64add7dad04da09ccd7',
  :domain      => ".peanut.dev"
}

# Configure memcache
config.cache_store  = :mem_cache_store, '127.0.0.1:11212', { :namespace => 'peanut' }

# ActiveMerchange configuration, using the Braintree gateway
config.after_initialize do 
  ActiveMerchant::Billing::Base.mode = :test 
end
 
config.to_prepare do
  Payment.gateway =
    ActiveMerchant::Billing::BraintreeGateway.new( 
      :login    => 'demo', 
      :password => 'password' 
  ) 
end

# Blueprint grid toggle switch
$BlueprintGrid = false

require 'ruby-debug'