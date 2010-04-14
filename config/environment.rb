# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Make sure the symlink to the shared models directory and shared lib directory are set up
# This is done after the boot so that RAILS_ENV and RAILS_ROOT are set up
models_path=File.expand_path(File.join(RAILS_ROOT, 'app/models'))

if !File.exists?(models_path)
  if RAILS_ENV == "production"
    source = File.join(RAILS_ROOT, '../../../walnut/current/app/models')
  else
    source = File.join(RAILS_ROOT, '../walnut/app/models')
  end
  puts "Looks like you do not have the models symbolic link set up. Attempting to link #{models_path} to shared models at #{source}."
  File.symlink(source, models_path)
else
  if File.symlink?(models_path)
    # puts "Looks like you have the shared lib symbolic link set up."
  else
    puts "Can't overwrite the existing file at #{models_path} with the symlink for shared models. No action being taken."
  end
end

lib_shared_path=File.expand_path(File.join(RAILS_ROOT, 'lib/shared'))

if !File.exists?(lib_shared_path)
  if RAILS_ENV == "production"
    source = File.join(RAILS_ROOT, '../../../walnut/current/lib')
  else
    source = File.join(RAILS_ROOT, '../walnut/lib')
  end
  puts "Looks like you do not have the models symbolic link set up. Attempting to link #{lib_shared_path} to shared lib at #{source}."
  File.symlink(source, lib_shared_path)
else
  if File.symlink?(lib_shared_path)
    # puts "Looks like you have the shared lib symbolic link set up."
  else
    puts "Can't overwrite the existing file at #{lib_shared_path} with the symlink for shared lib. No action being taken."
  end
end

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
  config.gem 'andand', :version => '~> 1.3.1', :source => "http://gems.github.com"
  config.gem "chronic", :version => '~> 0.2.3'
  config.gem "crack" # used by google weather plugin
  config.gem 'curb'
  config.gem "eventfulapi", :lib => false
  config.gem "geokit" 
  config.gem "haml", :version => '2.2.4'
  config.gem 'hoptoad_notifier'
  config.gem "hpricot" # required by sanitize, uses native components
  config.gem "httparty" # used by google weather plugin
  config.gem 'json' # uses native components
  config.gem 'mbleigh-subdomain-fu', :source => "http://gems.github.com", :lib => "subdomain-fu"
  config.gem 'mechanize'
  config.gem 'mime-types', :lib => false
  config.gem 'mislav-will_paginate', :version => '~> 2.3.6', :lib => 'will_paginate', :source => "http://gems.github.com"
  config.gem 'prawn'
  config.gem 'ri_cal', :version => '~> 0.8.5'
  config.gem 'rubyist-aasm', :lib => 'aasm', :source => "http://gems.github.com"
  config.gem 'sanitize', :version => '~> 1.0.6', :source => "http://gems.github.com"
  config.gem 'whenever', :version => '0.4.1', :lib => false, :source => 'http://gemcutter.org/'
  config.gem 'twiliolib'

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/lib/shared #{RAILS_ROOT}/lib/shared/jobs #{RAILS_ROOT}/lib/jobs )

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
require "#{RAILS_ROOT}/lib/duration.rb"
require "#{RAILS_ROOT}/lib/shared/array.rb"
require "#{RAILS_ROOT}/lib/shared/string.rb"
require "#{RAILS_ROOT}/lib/shared/time_calculations.rb"

# Pull in the serialized_hash functionality
require "#{RAILS_ROOT}/lib/shared/serialized_hash.rb"

# Base domain, used by subdomain_fu
DOMAIN = '.walnutcalendar.com'
