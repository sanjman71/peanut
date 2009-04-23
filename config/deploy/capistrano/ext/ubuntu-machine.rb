unless Capistrano::Configuration.respond_to?(:instance)
  abort "Requires Capistrano 2"
end

# Dir["#{File.dirname(__FILE__)}/ubuntu-machine/*.rb"].each { |lib| 
#   Capistrano::Configuration.instance.load {load(lib)}   
# }

load("#{File.dirname(__FILE__)}/ubuntu-machine/apache.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/aptitude.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/gems.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/git.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/helpers.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/iptables.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/machine.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/mysql.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/php.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/postfix.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/ruby.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/ssh.rb")
load("#{File.dirname(__FILE__)}/ubuntu-machine/utils.rb")
