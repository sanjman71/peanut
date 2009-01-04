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

# Create a hosts hash, useful when we have more than 1 host
hosts               = Hash.new
hosts[:slicehost]   = '173.45.229.171:30001'

role :app,          hosts[:slicehost]
role :web,          hosts[:slicehost]
role :db,           hosts[:slicehost], :primary => true

# Users, groups
set :user,          'peanut'  # log into servers as
set :group,         'peanut'

# Load external recipe files files
load_paths << "config/mongrel"
load "mongrel_tasks"

