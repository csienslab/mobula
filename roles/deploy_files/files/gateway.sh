#!/usr/bin/env bash

BASEDIR=$(dirname "$0")
source ${BASEDIR}/config.conf

# Bring up the loopback
ip link set lo up

# Setup the direct network
ip addr add ${GW_DIRIF_IP}/31 dev ${GW_DIRIF}
ip link set ${GW_DIRIF} up

# Setup the access network
ip addr add ${GATEWAY_NET} dev ${GW_ACCIF}
ip link set ${GW_ACCIF} up

# Setup the external network
ip link set ${GW_EXTIF} address ${EXT_MACADDR}
ip addr add ${EXT_NET} dev ${GW_EXTIF}
ip link set ${GW_EXTIF} up
ip route add default via ${EXT_GATEWAY}

# Setup the iptables and enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
# General NAT
iptables -w 10 -t nat -A POSTROUTING -o ${GW_EXTIF} -j MASQUERADE
iptables -w 10 -t nat -A POSTROUTING -o ${GW_WGIF} -j MASQUERADE
# ExtraWire NAT
iptables -w 10 -t nat -A POSTROUTING -s ${EW_SUBNET} -o ${GW_ACCIF} -j MASQUERADE
# SSH forwarding
iptables -w 10 -t nat -A PREROUTING -i ${GW_EXTIF} -p tcp --dport 22 -j DNAT --to-destination ${HS_DIRIF_IP}
# VXLAN forwarding
iptables -w 10 -t nat -A PREROUTING -i ${GW_WGIF} -p udp --dport 4789 -j DNAT --to-destination ${HS_DIRIF_IP}

# Enhance the firewall
iptables -w 10 -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allow ping on the external interface
iptables -w 10 -A INPUT -i ${GW_EXTIF} -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT
# Open WireGuard on the external interface
iptables -w 10 -A INPUT -i ${GW_EXTIF} -p udp --dport 51820 -j ACCEPT
iptables -w 10 -A INPUT -i ${GW_EXTIF} -j DROP
iptables -w 10 -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Only forward SSH from the external interface
iptables -w 10 -A FORWARD -i ${GW_EXTIF} -p tcp --dport 22 -j ACCEPT
iptables -w 10 -A FORWARD -i ${GW_EXTIF} -j DROP
# Block all IPv6 traffic from the external interface
ip6tables -w 10 -A INPUT -i ${GW_EXTIF} -j DROP
ip6tables -w 10 -A FORWARD -i ${GW_EXTIF} -j DROP

# Setup WireGuard
wg-quick up ${BASEDIR}/${GW_WGIF}.conf

# Start the DNS Server
${BASEDIR}/run_dns_server.sh &
