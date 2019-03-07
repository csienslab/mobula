#!/usr/bin/env bash

BASEDIR=$(dirname "$0")
source ${BASEDIR}/config.conf

# Clean the existed interfaces and namespaces
ip link del ${HS_EXTIF} 2>/dev/null
ip link del ${GW_ACCIF} 2>/dev/null
ip link del ${OVS_ACCIF} 2>/dev/null
ip link del ${OVS_FACIF} 2>/dev/null
ip link del ${HS_FACIF} 2>/dev/null
ip link del ${GW_DIRIF} 2>/dev/null
ip link del ${HS_DIRIF} 2>/dev/null
ip netns del ${NS_NAME} 2>/dev/null

# Setup interfaces and namespaces
ip netns add ${NS_NAME}

# Setup the direct network
ip link add ${GW_DIRIF} type veth peer name ${HS_DIRIF}
ip link set ${GW_DIRIF} netns ${NS_NAME}
ip addr add ${HS_DIRIF_IP}/31 dev ${HS_DIRIF}
ip link set ${HS_DIRIF} up

# Setup the access link
ip link add ${OVS_ACCIF} type veth peer name ${GW_ACCIF}
ip link set ${GW_ACCIF} netns ${NS_NAME}
ip link set ${OVS_ACCIF} up

# Duplicate the external interface
ip link add link ${EXT_IF} ${HS_EXTIF} type macvlan
# Move the original external interface into the namespace
# EXT_IF == GW_EXTIF
ip link set ${EXT_IF} netns ${NS_NAME}

# Setup the gateway
ip netns exec ${NS_NAME} ${BASEDIR}/gateway.sh

# Setup the routing rules for the direct network
ip route add table 20 default via ${GW_DIRIF_IP} dev ${HS_DIRIF}
# Route all traffic from the direct ip to the direct network
ip rule add from ${HS_DIRIF_IP} table 20 priority 10
# Route the WireGuard network to the direct network
ip rule add fwmark 0x573 table 20 priority 11
# Flush routing cache
ip route flush cache

# Enable the ARP filter
echo 1 > /proc/sys/net/ipv4/conf/all/arp_filter
# Setup the fast path table
ip rule add to ${HS_SUBNET} table 21 priority 12
# Setup WireGuard
wg-quick up ${BASEDIR}/${HS_WGIF}.conf
# Flush routing cache
ip route flush cache

# Setup the facade interface
ip link add ${HS_FACIF} type veth peer name ${OVS_FACIF}
ip link set ${HS_FACIF} mtu 1370
ip link set ${HS_FACIF} up
ip link set ${OVS_FACIF} up
