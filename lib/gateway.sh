#!/usr/bin/env bash

source ${BASEDIR}/constants.conf
source ${BASEDIR}/network.conf

# Bring up the loopback
ip link set lo up

# Setup the direct network
ip addr add ${GW_DIRIF_IP}/31 dev ${GW_DIRIF}
ip link set ${GW_DIRIF} up

# Setup the access network
ip addr add ${GATEWAY_NET} dev ${GW_ACCIF}
ip link set ${GW_ACCIF} up

# Setup the external network
ip link set ${GW_EXTIF} address ${GW_EXT_MACADDR}
ip addr add ${EXT_NET} dev ${GW_EXTIF}
ip link set ${GW_EXTIF} up
ip route add default via ${EXT_GATEWAY}

# Setup the iptables and enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
# General NAT
iptables -t nat -A POSTROUTING -o ${GW_EXTIF} -j MASQUERADE
iptables -t nat -A POSTROUTING -o ${GW_WGIF} -j MASQUERADE
# SSH forwarding
iptables -t nat -A PREROUTING -i ${GW_EXTIF} -p tcp --dport 22 -j DNAT --to-destination ${HS_DIRIF_IP}
# VXLAN forwarding
iptables -t nat -A PREROUTING -i ${GW_WGIF} -p udp --dport 4789 -j DNAT --to-destination ${HS_DIRIF_IP}

# Enhance the firewall
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allow ping on the external interface
iptables -A INPUT -i ${GW_EXTIF} -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT
# Open WireGuard on the external interface
iptables -A INPUT -i ${GW_EXTIF} -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -i ${GW_EXTIF} -j DROP
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Only forward SSH from the external interface
iptables -A FORWARD -i ${GW_EXTIF} -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -i ${GW_EXTIF} -j DROP
# Block all IPv6 traffic from the external interface
ip6tables -A INPUT -i ${GW_EXTIF} -j DROP
ip6tables -A FORWARD -i ${GW_EXTIF} -j DROP

# Setup WireGuard
wg-quick up ${BASEDIR}/${GW_WGIF}.conf

# Start DNS Server
${BASEDIR}/run_dns_server.sh &

# Test and update ARP of the external gateway
ping -W 6 -c 10 ${EXT_GATEWAY} &
