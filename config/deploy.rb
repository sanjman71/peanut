# Add our local deployment scripts directory
load_paths << "config/deploy"
# File.expand_path(File.dirname(__FILE__) + "config/deploy")

# Assuming you have just one ec2 server, set it's public DNS name here:
set :server_name, "ec2-174-129-117-111.compute-1.amazonaws.com"

# Be explicit about our different environments
# set :stages, %w(staging production)
# require 'capistrano/ext/multistage'

# Set application name
set :application,   "peanut"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to,     "/usr/apps/#{application}"

# Git repository
set :scm,           :git
set :repository,    'git@github.com:sanjman71/peanut.git'
set :branch,        "master"
set :deploy_via,    :remote_cache

# Users, groups
set :user,          'peanut'  # log into servers as
set :group,         'peanut'

# Load external recipe files
# load "database_tasks"

# use the ubuntu machine gem
load 'capistrano/ext/ubuntu-machine'

# Load data for provisioning resources
load "provisioning"
