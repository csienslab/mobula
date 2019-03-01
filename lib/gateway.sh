#!/usr/bin/env bash

source ${BASEDIR}/constants.conf
source ${BASEDIR}/network.conf

# Bring up the interfaces
ip link set lo up
ip link set ${GW_INTIF} up
ip link set ${GW_EXTIF} up

# Setup the gateway network
ip addr add ${GATEWAY_NET} dev ${GW_INTIF}

# Setup the external network
ip addr add ${EXT_NET} dev ${GW_EXTIF}
ip route add default via ${EXT_GATEWAY}

# Setup the iptables and enable forwarding
iptables -t nat -A POSTROUTING -o ${GW_EXTIF} -j MASQUERADE
iptables -t nat -A PREROUTING -i ${GW_EXTIF} -p tcp --dport 22 -j DNAT --to-destination ${VETH_M0_IP}:22
echo 1 > /proc/sys/net/ipv4/ip_forward

# Test and update the ARP of the external gateway
ping -W 6 -c 10 ${EXT_GATEWAY} &
