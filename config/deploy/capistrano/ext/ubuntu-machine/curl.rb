namespace :curl do
  desc "Install curl"
  task :install, :roles => :web do
    sudo "aptitude install curl -y"
  end
end