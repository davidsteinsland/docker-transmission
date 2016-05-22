FROM debian:jessie

# Update packages and install software
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/*

ENV GOSU_VERSION 1.7
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN apt-get update && apt-get install -y \
    software-properties-common \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    curl \
    openvpn \
    transmission-cli \
    transmission-common \
    transmission-daemon \
&& rm -rf /var/lib/apt/lists/*
# pmisc needed to get killall,
# gettext-base needed to get envsubst
RUN apt-get update && apt-get install -y \
    gettext-base \
    psmisc \
&& rm -rf /var/lib/apt/lists/*

RUN rm -rf /tmp/* /var/tmp/*

RUN mkdir /etc/transmission && chown debian-transmission:debian-transmission /etc/transmission

COPY settings.json.tmpl /etc/transmission/

RUN mkdir /config && chown debian-transmission:debian-transmission /config

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

RUN mkdir /data && chown debian-transmission:debian-transmission /data
VOLUME /data

# Expose port and run
EXPOSE 9091

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/transmission-daemon.sh"]
