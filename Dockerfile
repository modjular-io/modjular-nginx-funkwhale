FROM modjular/modjular-nginx:latest

LABEL maintainer="Jeffrey Phillips Freeman the@jeffreyfreeman.me"

RUN mkdir -p /etc/nginx/vhost.d/
COPY 01-copy-default-entry.sh /docker-entrypoint.d/
COPY funkwhale-proxy.conf /etc/nginx/vhost.d/

ENV FUNKWHALE_API_INTERNAL_HOST=host.docker.internal
ENV FUNKWHALE_API_INTERNAL_PORT=5000
ENV FUNKWHALE_FRONTEND_PATH=/srv/funkwhale/front/dist
ENV MEDIA_ROOT=/srv/funkwhale/data/media
ENV MUSIC_DIRECTORY_PATH=/srv/funkwhale/data/music
ENV STATIC_ROOT=/srv/funkwhale/data/static
