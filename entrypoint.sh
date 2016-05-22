#!/usr/bin/env sh

set -e

until ip addr show dev tun0 2>/dev/null;
do
  sleep 1
done

if [ $EUID -eq 0 -a "$1" = '/transmission-daemon.sh' ];
then
  if [ ! -z "${TRANSMISSION_GROUP_ID}" ];
  then
    echo "Changing GID to $TRANSMISSION_GROUP_ID"
    #groupmod -g $TRANSMISSION_GROUP_ID -o transmission
    delgroup transmission
    addgroup -g $TRANSMISSION_GROUP_ID -S transmission
  fi

  if [ ! -z "${TRANSMISSION_USER_ID}" ];
  then
    echo "Changing UID to $TRANSMISSION_USER_ID"
    #usermod -u $TRANSMISSION_USER_ID -o transmission
    deluser transmission
    adduser -S -u $TRANSMISSION_USER_ID -G transmission transmission
  fi

  chown -R transmission:transmission /etc/transmission
  chown -R transmission:transmission /config

  exec gosu transmission "$@"
fi

exec "$@"
