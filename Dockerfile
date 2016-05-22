FROM alpine:3.3

RUN apk add --update \
    openvpn \
    transmission-daemon \
    wget \
    && rm -rf /var/cache/apk/*

ENV GOSU_VERSION 1.7
RUN set -x \
    && apk add --no-cache --virtual .gosu-deps \
        dpkg \
        gnupg \
        openssl \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
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

ENV "OPENVPN_USERNAME=" \
    "OPENVPN_PASSWORD=" \
    "PIA_CLIENT_ID_FILE=/etc/transmission/pia_client_id" \
    "TRANSMISSION_USER_ID=" \
    "TRANSMISSION_GROUP_ID=" \
    "TRANSMISSION_BLOCKLIST_URL=http://john.bitsurge.net/public/biglist.p2p.gz" \
    "TRANSMISSION_BLOCKLIST_ENABLED=false" \
    "TRANSMISSION_DOWNLOAD_DIR=/data/completed" \
    "TRANSMISSION_INCOMPLETE_DIR=/data/incompleted" \
    "TRANSMISSION_INCOMPLETE_ENABLED=false" \
    "TRANSMISSION_RATIO_LIMIT=0.0" \
    "TRANSMISSION_RPC_BIND_ADDRESS=" \
    "TRANSMISSION_RPC_PASSWORD=password" \
    "TRANSMISSION_RPC_PORT=9091" \
    "TRANSMISSION_RPC_URL=/transmission/" \
    "TRANSMISSION_RPC_USERNAME=username" \
    "TRANSMISSION_RPC_WHITELIST=" \
    "TRANSMISSION_UMASK=2" \
    "TRANSMISSION_HOME=/etc/transmission"

RUN mkdir /data && chown transmission:transmission /data
VOLUME /data

# Expose port and run
EXPOSE 9091

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/transmission-daemon.sh"]
