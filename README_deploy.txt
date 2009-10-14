Setting up Rackspace Cloud servers for peanut deployment.

Need to add the ssh identity file for github. Can't share the same file with walnut, so we need to tell ssh when to use this file.
We do this by creating a virtual host in the ssh config and saying to use this new identity file with this host.
The host is in fact github.com. The configuration is as follows:

  app@mossoserver1:~$ cat .ssh/config 
  Host peanut_github
    Hostname=github.com
    IdentityFile=~/.ssh/id_rsa_peanut


I needed this on my development desktop also for some reason. In this case I remove the identity file specification:
  killian@skellig ~/development/walnut#master: cat ~/.ssh/config 
  Host peanut_github
    Hostname=github.com


Once this is done you should be able to ssh to peanut_github from the server as follows:
  app@mossoserver1:~$ ssh git@peanut_github
  ERROR: Hi sanjman71/peanut! You've successfully authenticated, but GitHub does not provide shell access
  Connection to github.com closed.

To create the directories you need on the server, run the following on the client machine:
  cap staging deploy

But then you'll need to fix the permissions:
  chown -R app:app /usr/apps/peanut

You should migrate the db to the latest version. Assuming you already have walnut deployed, this requires you go go
into the /usr/apps/walnut/current directory and do:
  rake db:migrate

Now, back on the client side, deploy the application:
  cap staging deploy

It will probably have a bunch of problems starting up. The biggest reason for this will be that it's missing gems.
The rake gems:install doesn't work, instead you need to install these individually by hand:
  sudo gem install prawn
  sudo gem install crack --no-rdoc --no-ri
  sudo gem install hpricot --no-rdoc --no-ri
  sudo gem install httparty --no-rdoc --no-ri

When installing the final gem, sanitize, I had issues, and had to install some packages on Ubuntu first.

  sudo aptitude install libxml2-dev
  sudo aptitude install libxslt-dev
This latter actually installed libxslt1-dev, and required installation of libxslt1.1 first, both of which I agreed to.

Then, once these are installed:
  sudo gem install sanitize --no-rdoc --no-ri


Finally, install the application static data, including the demos:
  rake init:dev_data

At this point, you can restart the application
  touch tmp/restart.txt
