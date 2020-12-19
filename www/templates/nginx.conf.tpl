daemon              off;
worker_processes    2;
user                www-data;
error_log           stderr;

events {
  worker_connections  1024;
}

http {
    server_tokens off;
    charset       utf-8;
    include       mime.types;

    server {
        access_log /storage/logs/{{env.Getenv "HOSTNAME"}}_access.log;

        listen       0.0.0.0:443 ssl;

        server_name {{env.Getenv "HOSTNAME"}};

        ssl_certificate     /storage/ssl/default/certificate.pem;
        ssl_certificate_key /storage/ssl/default/private_key.pem;

        ssl_protocols TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
        ssl_session_timeout  10m;
        ssl_session_cache shared:SSL:10m;
        ssl_session_tickets off;

        location / {
            root /storage/html;
            index index.html;
        }
    }

    server {
      listen       80;
      server_name  _;

      location / {
        return 301 https://$host$request_uri;
      }
    }
}
