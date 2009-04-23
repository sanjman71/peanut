namespace :sphinx do
  desc "Install Sphinx"
  task :install, :roles => :app do
    sudo "sudo rm -Rf #{sphinx_version}.tar.gz"
    run "curl -O http://www.sphinxsearch.com/downloads/#{sphinx_version}.tar.gz"
    run "tar xzvf #{sphinx_version}.tar.gz"
    run "cd #{sphinx_version}"
    run "cd #{sphinx_version} && ./configure"
    run "cd #{sphinx_version} && make"
    run "cd #{sphinx_version} && sudo make install"
    run "rm #{sphinx_version}.tar.gz"
    run "rm -Rf #{sphinx_version}"
  end
end
