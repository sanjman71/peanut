
# #######################################
# HOSTING PROVIDER CONFIGURATION
# Those tasks have been tested with several hosting providers
# and sometimes tasks are specific to those providers
set :hosting_provider, "ec2" # currently supported : ovh-rps, ovh-dedie, slicehost

# #######################################
# SERVER CONFIGURATION
# set :server_name, "YOUR_SERVER_NAME_HERE"
set :root_user, 'root'
# set :user, 'peanut'
set :setup_ssh, false # makes admin user not able to use ssh
ssh_options[:port] = 22
set :setup_iptables, false # We get this from ec2

# #######################################
# LOCAL CONFIGURATION
ssh_options[:keys] = "/Users/killian/.ec2/id_rsa-kdefault"
set :default_local_files_path, "/Users/killian/Desktop"


# #######################################
# SOFTWARE INSTALL CONFIGURATION

# SOFTWARE INSTALLATION OPTIONS
set :install_curl, true
set :install_mysql, true
set :install_apache, true
set :install_ruby, true
set :install_rubygems, true
set :install_ruby_enterprise, true
set :install_passenger, true
set :install_git, true
set :install_php, false
set :install_sphinx, true
set :configure_apparmor, true # necessary to allow MySQL to bulk import from /u/apps/
set :install_imagemagick, true
set :install_god, true

# version numbers
# NOTE: The latest version of Ruby Enterprise Edition is used unless you specify a version below.
# set :ruby_enterprise_version, "ruby-enterprise-1.8.6-20090113"
set :rubygem_version, "1.3.1"
set :passenger_version, "2.0.6"
set :git_version, "git-1.6.0.6"
set :sphinx_version, "sphinx-0.9.9-rc1"

# some Apache default values
set :default_server_admin, "killian@killianmurphy.com"
set :default_directory_index, "index.html"


role :gateway,  server_name
role :app,      server_name
role :web,      server_name
role :db,       server_name, :primary => true
