#!/usr/bin/env bash

source ${BASEDIR}/constants.conf
source ${BASEDIR}/network.conf

# Bring up the loopback
ip link set lo up

# Setup the direct network
ip addr add ${GW_DIRIF_IP}/31 dev ${GW_DIRIF}
ip link set ${GW_DIRIF} up

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
# General NAT
iptables -t nat -A POSTROUTING -o ${GW_EXTIF} -j MASQUERADE
iptables -t nat -A POSTROUTING -o ${GW_WGIF} -j MASQUERADE
# SSH bidirectional forwarding
iptables -t nat -A POSTROUTING -o ${GW_DIRIF} -p tcp --dport 22 -j SNAT --to-source ${GW_DIRIF_IP}
iptables -t nat -A PREROUTING -i ${GW_EXTIF} -p tcp --dport 22 -j DNAT --to-destination ${HS_DIRIF_IP}
# VXLAN forwarding
iptables -t nat -A PREROUTING -i ${GW_WGIF} -p udp --dport 4789 -j DNAT --to-destination ${HS_DIRIF_IP}

# Enhance the firewall
# Only open WireGuard on the external interface
iptables -A INPUT -i ${GW_EXTIF} -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -i ${GW_EXTIF} -j DROP
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Only forward SSH from the external interface
iptables -A FORWARD -i ${GW_EXTIF} -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -i ${GW_EXTIF} -j DROP

# Setup WireGuard
wg-quick up ${BASEDIR}/${GW_WGIF}.conf

# Test and update ARP of the external gateway
ping -W 6 -c 10 ${EXT_GATEWAY} &
