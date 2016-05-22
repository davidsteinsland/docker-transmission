#!/usr/bin/env bash

set -e

until ip addr show dev tun0 2>/dev/null;
do
  sleep 1
done

if [ $EUID -eq 0 -a "$1" = '/transmission-daemon.sh' ];
then
  if [ ! -z "${TRANSMISSION_USER_ID}" ];
  then
    echo "Changing UID to $TRANSMISSION_USER_ID"
    usermod -u $TRANSMISSION_USER_ID -o debian-transmission
  fi

  if [ ! -z "${TRANSMISSION_GROUP_ID}" ];
  then
    echo "Changing GID to $TRANSMISSION_GROUP_ID"
    groupmod -g $TRANSMISSION_GROUP_ID -o debian-transmission
  fi

  exec gosu debian-transmission "$@"
fi

exec "$@"
