#!/usr/bin/env bash

export BASEDIR=$(dirname "$0")
source ${BASEDIR}/constants.conf
source ${BASEDIR}/network.conf

# Clean the existed interfaces and namespaces
ip link del ${GW_EXTIF} 2>/dev/null
ip link del ${GW_INTIF} 2>/dev/null
ip link del ${OVS_INTIF} 2>/dev/null
ip link del ${HOST_VETH} 2>/dev/null
ip link del ${OVS_VETH} 2>/dev/null
ip netns del ${NS_NAME} 2>/dev/null

# Setup the interfaces and namespaces
ip netns add ${NS_NAME}

ip link add ${OVS_INTIF} type veth peer name ${GW_INTIF}
ip link set ${GW_INTIF} netns ${NS_NAME}
ip link set ${OVS_INTIF} up

ip link add ${HOST_VETH} type veth peer name ${OVS_VETH}
ip link set ${HOST_VETH} up
ip link set ${OVS_VETH} up

ip link add link ${EXT_IF} ${GW_EXTIF} type macvlan
ip link set ${GW_EXTIF} netns ${NS_NAME}

# Bring up the outdoor interface
ip link set ${EXT_IF} up

# Setup the gateway
ip netns exec ${NS_NAME} ${BASEDIR}/gateway.sh
