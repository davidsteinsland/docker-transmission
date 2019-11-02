#!/usr/bin/env sh

set -e

_LAN_IP=$(ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
_LAN_SUBNET=$(ip -o addr show eth0 | awk '$3 == "inet" { print $4 }')

if [ -z "${TRANSMISSION_RPC_BIND_ADDRESS}" ];
then
  export TRANSMISSION_RPC_BIND_ADDRESS=$_LAN_IP
fi

if [ -z "${TRANSMISSION_RPC_WHITELIST}" ];
then
  export TRANSMISSION_RPC_WHITELIST=$_LAN_SUBNET
fi

# make sure transmission directory is setup OK
if [ ! -d "${TRANSMISSION_HOME}" ];
then
  mkdir -p "${TRANSMISSION_HOME}"
fi

if [ ! -d "${TRANSMISSION_DOWNLOAD_DIR}" ];
then
  mkdir -p "${TRANSMISSION_DOWNLOAD_DIR}"
fi

if [ ! -d "${TRANSMISSION_INCOMPLETE_DIR}" ];
then
  mkdir -p "${TRANSMISSION_INCOMPLETE_DIR}"
fi

if [ ! -z "${OPENVPN_USERNAME}" ];
then
  _VPN_IP=$(ip -o addr show dev tun0 | awk '{print $4}')
  export TRANSMISSION_BIND_ADDRESS_IPV4=$_VPN_IP
fi

echo "Using IP $TRANSMISSION_BIND_ADDRESS_IPV4"

if [ -z "${TRANSMISSION_PEER_PORT}" ];
then
  TRANSMISSION_PEER_PORT="1337"
fi

echo "Using port $TRANSMISSION_PEER_PORT"

# substitute configuration file with environmental variables
envsubst < /etc/transmission/settings.json.tmpl > $TRANSMISSION_HOME/settings.json

set -x
TRANSMISSION_OPTS="--bind-address-ipv4 $TRANSMISSION_BIND_ADDRESS_IPV4
   --peerport $TRANSMISSION_PEER_PORT
   --rpc-bind-address $TRANSMISSION_RPC_BIND_ADDRESS
   --encryption-preferred
   --global-seedratio $TRANSMISSION_RATIO_LIMIT
   --config-dir $TRANSMISSION_HOME"

echo "Up script:"
echo $TRANSMISSION_UP_SCRIPT
if [ -f $TRANSMISSION_UP_SCRIPT ];
then
  . $TRANSMISSION_UP_SCRIPT
fi

exec transmission-daemon --foreground ${TRANSMISSION_OPTS}

