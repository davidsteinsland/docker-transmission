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

if [ ! -z "${OPENVPN_USERNAME}" ];
then
  if [ ! -f "${PIA_CLIENT_ID_FILE}" ];
  then
    echo "Generating new client ID"
    head -n 100 /dev/urandom | md5sum | tr -d " -" | tee $PIA_CLIENT_ID_FILE
  fi

  echo "Fetching client ID from ${PIA_CLIENT_ID_FILE}"

  PIA_CLIENT_ID=$(cat $PIA_CLIENT_ID_FILE)

  echo 'Loading port forward assignment information..'

  _PIA_RESPONSE=$(curl "http://209.222.18.222:2000/?client_id=$PIA_CLIENT_ID" 2>/dev/null)
  echo $_PIA_RESPONSE
  if [ "${_PIA_RESPONSE}" == "" ]; then
    echo "Port forwarding is already activated on this connection, has expired, or you are not connected to a PIA region that supports port forwarding"
    exit 1
  fi
  export TRANSMISSION_PEER_PORT=$(echo $_PIA_RESPONSE | head -1 | grep -oE "[0-9]+")
  echo "Using port $TRANSMISSION_PEER_PORT"
fi

if [ -z "${TRANSMISSION_PEER_PORT}" ];
then
  echo "Failed to fetch port number"
  exit 1
fi

echo "Using port $TRANSMISSION_PEER_PORT"

# substitute configuration file with environmental variables
envsubst < /etc/transmission/settings.json.tmpl > $TRANSMISSION_HOME/settings.json

TRANSMISSION_OPTS="--bind-address-ipv4 $TRANSMISSION_BIND_ADDRESS_IPV4
   --peerport $TRANSMISSION_PEER_PORT
   --rpc-bind-address $TRANSMISSION_RPC_BIND_ADDRESS
   --encryption-preferred
   --global-seedratio $TRANSMISSION_RATIO_LIMIT
   --config-dir $TRANSMISSION_HOME"

exec transmission-daemon --foreground ${TRANSMISSION_OPTS}
