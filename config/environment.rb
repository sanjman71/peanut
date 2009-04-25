# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem 'mbleigh-subdomain-fu', :source => "http://gems.github.com", :lib => "subdomain-fu"
  config.gem "chronic", :version => '~> 0.2.3'
  config.gem "haml", :version => '~> 2.0.9', :source => "git://github.com/nex3/haml.git"
  config.gem "starling", :version => '~> 0.9.8'
  config.gem 'rubyist-aasm', :version => '~> 2.0.2', :lib => 'aasm', :source => "http://gems.github.com"
  config.gem 'mislav-will_paginate', :version => '~> 2.3.6', :lib => 'will_paginate', :source => "http://gems.github.com"
  config.gem 'sanitize', :version => '~> 1.0.6', :source => "http://gems.github.com"
  config.gem 'prawn', :version => '~> 0.4.1'
  
  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Prevent the lib directory from being reloaded
  # Avoid the problem: A copy of AuthenticatedSystem has been removed from the module tree but is still active!
  config.load_once_paths += %W( #{RAILS_ROOT}/lib )
  
  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.active_record.default_timezone = :utc
  config.time_zone = 'Central Time (US & Canada)'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  #
  # Moved this to dev, test and production .rb files so that we can use different domains for each - peanut.dev, peanut.test and peanut.com

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  # config.active_record.observers = :user_observer
  
  # Turn off timestamped migrations
  config.active_record.timestamped_migrations = false
end

# Extend ruby classes
require "#{RAILS_ROOT}/lib/range.rb"
require "#{RAILS_ROOT}/lib/array.rb"
require "#{RAILS_ROOT}/lib/string.rb"
require "#{RAILS_ROOT}/lib/duration.rb"

# Initialize workling to use starling
Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new

# Initialize exception notifier
ExceptionNotifier.exception_recipients  = %w(peanut-exception@jarna.com)
ExceptionNotifier.sender_address        = %("peanut error" <app.error@peanut.com>)
ExceptionNotifier.email_prefix          = "[app] "

# 
DOMAIN = '.walnutcalendar.com'

# Define all gem requirements
require "will_paginate"
