#!/usr/bin/env bash

source ${BASEDIR}/constants.conf
source ${BASEDIR}/network.conf

# Bring up the loopback
ip link set lo up

# Setup the gateway network
ip addr add ${GATEWAY_NET} dev ${GW_INTIF}
ip link set ${GW_INTIF} up

# Setup the external network
ip link set ${GW_EXTIF} address ${EXT_MACADDR}
ip addr add ${EXT_NET} dev ${GW_EXTIF}
ip link set ${GW_EXTIF} up
ip route add default via ${EXT_GATEWAY}

# Setup the iptables and enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o ${GW_EXTIF} -j MASQUERADE
iptables -t nat -A PREROUTING -i ${GW_EXTIF} -p tcp --dport 22 -j DNAT --to-destination ${VETH_M0_IP}:22
iptables -t nat -A PREROUTING -i ${GW_EXTIF} -p udp --dport 51820 -j DNAT --to-destination ${VETH_M0_IP}:51820

# Enhance the firewall
iptables -A INPUT -i ${GW_EXTIF} -j DROP
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Only forward SSH and WireGuard from the external interface
iptables -A FORWARD -i ${GW_EXTIF} -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -i ${GW_EXTIF} -p udp --dport 51820 -j ACCEPT
iptables -A FORWARD -i ${GW_EXTIF} -j DROP

# Test and update ARP of the external gateway
ping -W 6 -c 10 ${EXT_GATEWAY} &
