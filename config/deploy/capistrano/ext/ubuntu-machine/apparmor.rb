namespace :apparmor do
  desc "Update apparmor with a profile that allows MySQL to read CSV & SQL files"
  # Without this, MySQL is unable to do 'LOAD DATA INFILE' and bulk load data
  task :configure_apparmor, :roles => :web do
    put render("usr.sbin.mysqld", binding), "usr.sbin.mysqld"
    sudo "mv usr.sbin.mysqld /etc/apparmor.d/usr.sbin.mysqld"
    restart
  end
  
  desc "Restarts Apparmor"
  task :restart, :roles => :web do
    sudo "/etc/init.d/apparmor reload"
  end
end