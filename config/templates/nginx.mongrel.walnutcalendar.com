upstream mongrel {
  server 127.0.0.1:5000;
}

# Redirect peanutcalendar.com to www.peanutcalendar.com
server {
  listen          80;
  server_name     peanutcalendar.com;
  rewrite ^/(.*)  http://www.peanutcalendar.com/$1 permanent;
}


server {
  listen      80;
  server_name *.peanutcalendar.com;

  access_log  /usr/apps/peanut/current/log/access.log;
  error_log   /usr/apps/peanut/current/log/error.log;

  root        /usr/apps/peanut/current/public/;
  index       index.html;

  location / {
    proxy_set_header  X-Real-IP  $remote_addr;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect false;

    if (-f $request_filename/index.html) {
      rewrite (.*) $1/index.html break;
    }

    if (-f $request_filename.html) {
      rewrite (.*) $1.html break;
    }

    if (!-f $request_filename) {
      proxy_pass http://mongrel;
      break;
    }
  }
}
