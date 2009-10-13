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
set :repository,    'git@peanut_github:sanjman71/peanut.git'
set :branch,        "master"
set :deploy_via,    :remote_cache

# Users, groups
set :user,          'app'  # log into servers as
set :group,         'app'

# Load external recipe files
load_paths << "config/recipes"
load "crontab"
load "database"
load "delayed_job"

deploy.task :restart, :roles => :app do
  run "touch #{current_release}/tmp/restart.txt"
end

deploy.task :init, :roles => :app do
  # first time initialization
  run "mkdir -p #{deploy_to}/releases"
  run "mkdir -p #{deploy_to}/shared/log"
  run "mkdir -p #{deploy_to}/shared/pids"
end

after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"

after "deploy", "database:configure"
