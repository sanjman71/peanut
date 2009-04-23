set :gem_path do
  "/usr/bin/"
end
set :ree_path do
  "/opt/ruby-enterprise/bin/"
end

namespace :imagemagick do
  task :install_core, :roles => :web do
    sudo "apt-get install imagemagick libmagick9-dev libfreetype6-dev xml-core -y"
    sudo "apt-get install librmagick-ruby1.8 librmagick-ruby-doc -y" if install_ruby
  end
  desc "Install ImageMagick"
  task :install, :roles => :web do
    install_core
    sudo "#{gem_path}gem install rmagick" if install_ruby && install_rubygems
    sudo "#{ree_path}gem install rmagick" if install_ruby && install_rubygems && install_ruby_enterprise
  end
  desc "Install ImageMagick for Ruby Enterprise Edition"
  task :install_for_REE, :roles => :web do
    install_core
    sudo "#{ree_path}gem install rmagick" if install_ruby && install_rubygems && install_ruby_enterprise
  end
end
