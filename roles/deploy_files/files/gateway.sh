#!/usr/bin/env bash

TIMEOUT=10
BASEDIR=$(dirname "$0")
source ${BASEDIR}/network.conf

# Bring up the loopback
ip link set lo up

# Setup the iptables and enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
# General NAT
iptables -w ${TIMEOUT} -t nat -A POSTROUTING -o ${GW_EXTIF} -j MASQUERADE
iptables -w ${TIMEOUT} -t nat -A POSTROUTING -s ${WG_SUBNET} -o ${GW_ACCIF} -j MASQUERADE
iptables -w ${TIMEOUT} -t nat -A POSTROUTING -d ${IWG_SUBNET} -o ${GW_WGIF} -j SNAT --to-source ${HS_DIRIF_IP}
# SSH forwarding
iptables -w ${TIMEOUT} -t nat -A PREROUTING -i ${GW_EXTIF} -p tcp --dport 22 -j DNAT --to-destination ${HS_DIRIF_IP}
# Enhance the firewall
iptables -w ${TIMEOUT} -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allow ping and WireGuard on the external interface
iptables -w ${TIMEOUT} -A INPUT -i ${GW_EXTIF} -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT
iptables -w ${TIMEOUT} -A INPUT -i ${GW_EXTIF} -p udp --dport 51820 -j ACCEPT
iptables -w ${TIMEOUT} -A INPUT -i ${GW_EXTIF} -j DROP
# Stateful forwarding
iptables -w ${TIMEOUT} -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allowed forwarding paths
iptables -w ${TIMEOUT} -A FORWARD -i ${GW_ACCIF} -j ACCEPT
iptables -w ${TIMEOUT} -A FORWARD -i ${GW_DIRIF} -o ${GW_WGIF} -j ACCEPT
iptables -w ${TIMEOUT} -A FORWARD -i ${GW_WGIF} -o ${GW_DIRIF} -j ACCEPT
iptables -w ${TIMEOUT} -A FORWARD -i ${GW_WGIF} -o ${GW_ACCIF} -j ACCEPT
iptables -w ${TIMEOUT} -A FORWARD -i ${GW_WGIF} -o ${GW_WGIF} -j ACCEPT
# Only forward SSH and WireGuard from the external interface
iptables -w ${TIMEOUT} -A FORWARD -i ${GW_EXTIF} -o ${GW_DIRIF} -p tcp --dport 22 -j ACCEPT
iptables -w ${TIMEOUT} -A FORWARD -j DROP
# Block all IPv6 traffic
ip6tables -w ${TIMEOUT} -A INPUT -j DROP
ip6tables -w ${TIMEOUT} -A OUTPUT -j DROP
ip6tables -w ${TIMEOUT} -A FORWARD -j DROP

# Setup the direct network
ip addr add ${GW_DIRIF_IP} dev ${GW_DIRIF}
ip link set ${GW_DIRIF} mtu ${WG_MTU}
ip link set ${GW_DIRIF} up
ip route add ${HS_DIRIF_IP} dev ${GW_DIRIF}

# Setup the access network
ip addr add ${GATEWAY_NET} dev ${GW_ACCIF}
ip link set ${GW_ACCIF} mtu ${ACC_MTU}
ip link set ${GW_ACCIF} up

# Setup the external network
ip link set ${GW_EXTIF} address ${EXT_MACADDR}
ip addr add ${EXT_NET} dev ${GW_EXTIF}
ip link set ${GW_EXTIF} up
ip route add default via ${EXT_GATEWAY}

# Setup WireGuard
wg-quick up ${BASEDIR}/${GW_WGIF}.conf

# Start the DNS Server
${BASEDIR}/run_dns_server.sh &
