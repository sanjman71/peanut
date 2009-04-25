namespace :rails do

  desc "Copy our git keys so that we can clone the repository"
  task :copy_git_keys, :roles => :app do
    run "mkdir -p ~/.ssh"
    run "chown -R #{user}:#{user} ~/.ssh"
    run "chmod 700 ~/.ssh"
    
    if git_key.size != ""
      priv_key = File.read("#{git_key}")
      pub_key = File.read("#{git_key}.pub")

      put priv_key, "/home/#{user}/.ssh/id_rsa", :mode => 0600
      put pub_key, "/home/#{user}/.ssh/id_rsa.pub", :mode => 0600
    end
    
  end
  
  desc "Install the required gems"
  task :install_gems, :roles => :app do
    run "rake gems:install"
  end

  desc "Install Rails"
  task :install_rails, :roles => :app do
    sudo "gem install rails -v#{rails_version}"
  end
  
end
