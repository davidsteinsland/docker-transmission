#!/usr/bin/env sh

set -e

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

echo "Waiting for ip on $TRANSMISSION_BIND_INTERFACE..."
until ip addr show dev $TRANSMISSION_BIND_INTERFACE &>/dev/null;
do
  sleep 1
done
until ip addr show dev $TRANSMISSION_RPC_BIND_INTERFACE &>/dev/null;
do
  sleep 1
done

BIND_INTERFACE_IP=$(ip -o addr show dev $TRANSMISSION_BIND_INTERFACE | awk '{print $4}')
RPC_BIND_INTERFACE_IP=$(ip -o addr show dev $TRANSMISSION_RPC_BIND_INTERFACE | awk '{print $4}')

if [ -z "${TRANSMISSION_BIND_ADDRESS_IPV4}" ];
then
  export TRANSMISSION_BIND_ADDRESS_IPV4=$BIND_INTERFACE_IP
fi

if [ -z "${TRANSMISSION_RPC_BIND_ADDRESS}" ];
then
  export TRANSMISSION_RPC_BIND_ADDRESS=$RPC_BIND_INTERFACE_IP
fi

echo "Bind address: $TRANSMISSION_BIND_ADDRESS_IPV4"
echo "RPC Bind address: $TRANSMISSION_RPC_BIND_ADDRESS"
echo "RPC whitelist: $TRANSMISSION_RPC_WHITELIST"

if [ -z "${TRANSMISSION_PEER_PORT}" ];
then
  TRANSMISSION_PEER_PORT="1337"
fi

echo "Using port $TRANSMISSION_PEER_PORT"

# substitute configuration file with environmental variables
envsubst < /etc/transmission/settings.json.tmpl > $TRANSMISSION_HOME/settings.json

echo "Up script:"
echo $TRANSMISSION_UP_SCRIPT
if [ -f $TRANSMISSION_UP_SCRIPT ];
then
  eval $TRANSMISSION_UP_SCRIPT &
fi

set -x
TRANSMISSION_OPTS="--bind-address-ipv4 $TRANSMISSION_BIND_ADDRESS_IPV4
   --peerport $TRANSMISSION_PEER_PORT
   --rpc-bind-address $TRANSMISSION_RPC_BIND_ADDRESS
   --encryption-preferred
   --global-seedratio $TRANSMISSION_RATIO_LIMIT
   --config-dir $TRANSMISSION_HOME"

exec transmission-daemon --foreground ${TRANSMISSION_OPTS}

