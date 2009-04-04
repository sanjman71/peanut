# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

MAIN_HOST = "www.peanutcalendar.com" 

config.action_controller.session = {
  :session_key => '_peanut_session',
  :secret      => '36791ab51cc708c1cf0314576d5a6a5fb5b1ecf2c4eebf911eeed605b2b666ffd62f24a93ae99519c100543b0ee9195866cdf0e088a0f64add7dad04da09ccd7',
  :domain      => ".peanutcalendar.com"
}
