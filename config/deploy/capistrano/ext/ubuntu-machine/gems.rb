namespace :gems do
  set :gem_path do
    "/usr/bin/"
  end
  
  desc "Install RubyGems"
  task :install_rubygems, :roles => :app do
    run "wget http://rubyforge.org/frs/download.php/45905/rubygems-#{rubygem_version}.tgz"
    run "tar xvzf rubygems-#{rubygem_version}.tgz"
    run "cd rubygems-#{rubygem_version} && sudo ruby setup.rb"
    sudo "ln -s /usr/bin/gem1.8 /usr/bin/gem"
    sudo "gem update"
    sudo "gem update --system"
    run "rm -Rf /tmp/rubygems-#{rubygem_version}*"
  end

  desc "List gems on remote server"
  task :list, :roles => :app do
    stream "#{gem_path}gem list"
  end

  desc "Update gems on remote server"
  task :update, :roles => :app do
    sudo "#{gem_path}gem update"
  end

  desc "Update gem system on remote server"
  task :update_system, :roles => :app do
    sudo "#{gem_path}gem update --system"
  end

  desc "Install a gem on the remote server"
  task :install, :roles => :app do
    name = Capistrano::CLI.ui.ask("Which gem should we install: ")
    sudo "#{gem_path}gem install #{name}"
  end
  
  desc "Uninstall a gem on the remote server"
  task :uninstall, :roles => :app do
    name = Capistrano::CLI.ui.ask("Which gem should we uninstall: ")
    sudo "#{gem_path}gem uninstall #{name}"
  end
end

  # Tasks for REE gems
namespace :ree_gems do
  set :ree_path do
    "/opt/ruby-enterprise/bin/"
  end

  desc "List REE gems on remote server"
  task :list, :roles => :app do
    stream "#{ree_path}gem list"
  end

  desc "Update REE gems on remote server"
  task :update, :roles => :app do
    sudo "#{ree_path}gem update"
  end

  desc "Update REE gem system on remote server"
  task :update_system, :roles => :app do
    sudo "#{ree_path}gem update --system"
  end

  desc "Install a REE gem on the remote server"
  task :install, :roles => :app do
    name = Capistrano::CLI.ui.ask("Which gem should we install: ")
    sudo "#{ree_path}gem install #{name}"
  end

  desc "Uninstall a REE gem on the remote server"
  task :uninstall, :roles => :app do
    name = Capistrano::CLI.ui.ask("Which gem should we uninstall: ")
    sudo "#{ree_path}gem uninstall #{name}"
  end
end
