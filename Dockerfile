FROM modjular/modjular-nginx:latest

LABEL maintainer="Jeffrey Phillips Freeman the@jeffreyfreeman.me"

COPY 01-copy-default-entry.sh /docker-entrypoint.d/
COPY funkwhale-proxy.conf /etc/nginx/vhost.d
