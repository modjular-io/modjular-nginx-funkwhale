#!/bin/bash
set -e

echo "Copying default.conf to conf.d directory for host ${FUNKWHALE_HOSTNAME}."
cat > "/etc/nginx/conf.d/default.conf" << EOF
upstream funkwhale-api {
    # depending on your setup, you may want to update this
    server ${FUNKWHALE_API_INTERNAL_HOST}:${FUNKWHALE_API_INTERNAL_PORT};
}


# required for websocket support
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
    listen [::]:80;
    server_name ${FUNKWHALE_HOSTNAME};

    # TLS
    # Feel free to use your own configuration for SSL here or simply remove the
    # lines and move the configuration to the previous server block if you
    # don't want to run funkwhale behind https (this is not recommended)
    # have a look here for let's encrypt configuration:
    # https://certbot.eff.org/all-instructions/#debian-9-stretch-nginx

    root ${FUNKWHALE_FRONTEND_PATH};

    # If you are using S3 to host your files, remember to add your S3 URL to the
    # media-src and img-src headers (e.g. img-src 'self' https://<your-S3-URL> data:)

    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
    add_header Referrer-Policy "strict-origin-when-cross-origin";


    location / {
        include /etc/nginx/vhost.d/funkwhale-proxy.conf;
        # this is needed if you have file import via upload enabled
        client_max_body_size 1024M;
        proxy_pass   http://funkwhale-api/;
    }

    location /front/ {
        add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
        add_header Referrer-Policy "strict-origin-when-cross-origin";

        add_header X-Frame-Options "ALLOW";
        alias ${FUNKWHALE_FRONTEND_PATH};
        expires 30d;
        add_header Pragma public;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    location /front/embed.html {
        add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
        add_header Referrer-Policy "strict-origin-when-cross-origin";

        add_header X-Frame-Options "ALLOW";
        alias ${FUNKWHALE_FRONTEND_PATH}/embed.html;
        expires 30d;
        add_header Pragma public;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    location /federation/ {
        include /etc/nginx/vhost.d/funkwhale-proxy.conf;
        proxy_pass   http://funkwhale-api/federation/;
    }

    # You can comment this if you do not plan to use the Subsonic API
    location /rest/ {
        include /etc/nginx/vhost.d/funkwhale-proxy.conf;
        proxy_pass   http://funkwhale-api/api/subsonic/rest/;
    }

    location /.well-known/ {
        include /etc/nginx/vhost.d/funkwhale-proxy.conf;
        proxy_pass   http://funkwhale-api/.well-known/;
    }

    location /media/ {
        alias ${MEDIA_ROOT}/;
    }

    # this is an internal location that is used to serve
    # audio files once correct permission / authentication
    # has been checked on API side
    # location /_protected/media {
    #     internal;
    #     alias   ${MEDIA_ROOT};
    # }
    # Comment the previous location and uncomment this one if you're storing
    # media files in a S3 bucket
    location ~ /_protected/media/(.+) {
        #resolver 10.0.0.2;
        internal;
        # Needed to ensure DSub auth isn't forwarded to S3/Minio, see #932
        proxy_set_header Authorization "";
        proxy_pass \$1;
    }

    location /_protected/music {
        # this is an internal location that is used to serve
        # audio files once correct permission / authentication
        # has been checked on API side
        # Set this to the same value as your MUSIC_DIRECTORY_PATH setting
        internal;
        alias   ${MUSIC_DIRECTORY_PATH};
    }

    location /staticfiles/ {
        # django static files
        alias ${STATIC_ROOT}/;
    }

EOF
