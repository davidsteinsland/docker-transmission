#!/usr/bin/env sh

set -e

if [ $(id -u) -eq 0 -a "$1" = '/transmission-daemon.sh' ];
then
  if [ ! -z "${TRANSMISSION_USER_ID}" ];
  then
    echo "Changing GID to $TRANSMISSION_GROUP_ID"
    #groupmod -g $TRANSMISSION_GROUP_ID -o transmission
    deluser transmission
    #delgroup transmission
    addgroup -S -g $TRANSMISSION_GROUP_ID transmission

    echo "Changing UID to $TRANSMISSION_USER_ID"
    adduser -S -G transmission -u $TRANSMISSION_USER_ID transmission
  fi

  chown -R transmission:transmission /etc/transmission
  chown -R transmission:transmission /config
  chown -R transmission:transmission /data

  exec gosu transmission "$@"
fi

exec "$@"
