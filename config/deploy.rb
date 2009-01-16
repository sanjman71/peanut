# Be explicit about our different environments
set :stages, %w(staging production)
require 'capistrano/ext/multistage'

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

# Load external recipe files files
load_paths << "config/mongrel"
load "mongrel_tasks"

