#!/usr/bin/env bash

export BASEDIR=$(dirname "$0")
source ${BASEDIR}/constants.conf
source ${BASEDIR}/network.conf

# Clean the existed interfaces and namespaces
ip link del ${GW_EXTIF} 2>/dev/null
ip link del ${GW_ACCIF} 2>/dev/null
ip link del ${OVS_ACCIF} 2>/dev/null
ip link del ${HS_VETHIF} 2>/dev/null
ip link del ${OVS_VETHIF} 2>/dev/null

ip link del ${HOST_DIRIF} 2>/dev/null
ip netns del ${NS_NAME} 2>/dev/null

# Setup interfaces and namespaces
ip netns add ${NS_NAME}

# Setup the direct network
ip link add ${GW_DIRIF} type veth peer name ${HS_DIRIF}
ip link set ${GW_DIRIF} netns ${NS_NAME}
ip addr add ${HS_DIRIF_IP}/31 dev ${HS_DIRIF}
ip link set ${HS_DIRIF} up

ip link add ${OVS_ACCIF} type veth peer name ${GW_ACCIF}
ip link set ${GW_ACCIF} netns ${NS_NAME}
ip link set ${OVS_ACCIF} up

ip link add ${HS_VETHIF} type veth peer name ${OVS_VETHIF}
ip link set ${HS_VETHIF} up
ip link set ${OVS_VETHIF} up

ip link add link ${EXT_IF} ${GW_EXTIF} type macvlan
ip link set ${GW_EXTIF} netns ${NS_NAME}

# Replace the original MAC address
ip link set ${EXT_IF} address ${RAND_MACADDR}
# Bring up the external interface
ip link set ${EXT_IF} up

# Setup the gateway
ip netns exec ${NS_NAME} ${BASEDIR}/gateway.sh

# Route the WireGuard network to the direct network
ip route add ${WG_SUBNET} via ${GW_DIRIF_IP} dev ${HS_DIRIF}
