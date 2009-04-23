namespace :memcached do
  desc "Install memcached"
  task :install, :roles => :web do
    sudo "apt-get install memcached -y"
    sudo "/etc/init.d/memcached start"
    sudo "ldconfig"
  end
end