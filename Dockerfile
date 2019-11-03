FROM alpine:3.10

RUN apk add --update \
    openvpn \
    transmission-daemon \
    wget \
    curl \
    && rm -rf /var/cache/apk/*

ENV GOSU_VERSION 1.11
RUN set -x \
    && apk add --no-cache --virtual .gosu-deps \
        dpkg \
        gnupg \
        openssl \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }').asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apk del .gosu-deps

RUN apk add --update gettext && rm -rf /var/cache/apk/*

RUN mkdir /etc/transmission && chown transmission:transmission /etc/transmission

COPY settings.json.tmpl /etc/transmission/

RUN mkdir /config && chown transmission:transmission /config

COPY entrypoint.sh /
COPY transmission-daemon.sh /

ENV TRANSMISSION_USER_ID=
ENV TRANSMISSION_GROUP_ID=
ENV TRANSMISSION_BLOCKLIST_URL=http://john.bitsurge.net/public/biglist.p2p.gz
ENV TRANSMISSION_BLOCKLIST_ENABLED=fase
ENV TRANSMISSION_DOWNLOAD_DIR=/data/completed
ENV TRANSMISSION_INCOMPLETE_DIR=/data/incompleted
ENV TRANSMISSION_INCOMPLETE_ENABLED=false
ENV TRANSMISSION_RATIO_LIMIT=0.0
ENV TRANSMISSION_BIND_INTERFACE="eth0"
ENV TRANSMISSION_RPC_BIND_INTERFACE="eth0"
ENV TRANSMISSION_BIND_ADDRESS=
ENV TRANSMISSION_RPC_BIND_ADDRESS=
ENV TRANSMISSION_RPC_PASSWORD=password
ENV TRANSMISSION_RPC_PORT=9091
ENV TRANSMISSION_RPC_URL=/transmission/
ENV TRANSMISSION_RPC_USERNAME=username
ENV TRANSMISSION_RPC_WHITELIST=
ENV TRANSMISSION_SPEED_LIMIT_UP=100
ENV TRANSMISSION_SPEED_LIMIT_ENABLED=false
ENV TRANSMISSION_UMASK=2
ENV TRANSMISSION_HOME=/etc/transmission
ENV TRANSMISSION_TORRENT_DONE_ENABLED=false
ENV TRANSMISSION_TORRENT_DONE_FILENAME=
ENV TRANSMISSION_UP_SCRIPT=

RUN mkdir /data && chown transmission:transmission /data
VOLUME /data

# Expose port and run
EXPOSE 9091

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/transmission-daemon.sh"]
