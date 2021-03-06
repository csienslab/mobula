#!/usr/bin/env bash

BASE_DIR="{{install_dir}}"
source ${BASE_DIR}/etc/constants.conf
source ${BASE_DIR}/etc/network.conf
TL=10

# Bring up the loopback
ip link set lo up

# Setup iptables and enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
# General NAT
iptables -w ${TL} -t nat -A POSTROUTING -o ${GW_EXTIF} -j MASQUERADE
iptables -w ${TL} -t nat -A POSTROUTING -s ${WG_SUBNET} -o ${OVS_BR} -j MASQUERADE
iptables -w ${TL} -t nat -A POSTROUTING -d ${IW_SUBNET} -o ${GW_WGIF} -j SNAT --to-source ${HS_DIRIF_IP}
# SSH forwarding
iptables -w ${TL} -t nat -A PREROUTING -i ${GW_EXTIF} -p tcp --dport 22 -j DNAT --to-destination ${HS_DIRIF_IP}
# Geneve forwarding
iptables -w ${TL} -t nat -A PREROUTING -i ${GW_WGIF} -p udp --dport 6254 -j DNAT --to-destination ${GW_DIRIF_IP}
# Enhance the firewall
iptables -w ${TL} -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allow ping and WireGuard on the external interface
iptables -w ${TL} -A INPUT -i ${GW_EXTIF} -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT
iptables -w ${TL} -A INPUT -i ${GW_EXTIF} -p udp --dport 51820 -j ACCEPT
iptables -w ${TL} -A INPUT -i ${GW_EXTIF} -j DROP
# Stateful forwarding
iptables -w ${TL} -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allowed forwarding paths
iptables -w ${TL} -A FORWARD -i ${OVS_BR} -j ACCEPT
iptables -w ${TL} -A FORWARD -i ${GW_DIRIF} -o ${GW_WGIF} -j ACCEPT
iptables -w ${TL} -A FORWARD -i ${GW_WGIF} -o ${GW_DIRIF} -j ACCEPT
iptables -w ${TL} -A FORWARD -i ${GW_WGIF} -o ${OVS_BR} -j ACCEPT
iptables -w ${TL} -A FORWARD -i ${GW_WGIF} -o ${GW_WGIF} -j ACCEPT
# Only forward SSH and WireGuard from the external interface
iptables -w ${TL} -A FORWARD -i ${GW_EXTIF} -o ${GW_DIRIF} -p tcp --dport 22 -j ACCEPT
iptables -w ${TL} -A FORWARD -j DROP
# Block all IPv6 traffic
ip6tables -w ${TL} -A INPUT -j DROP
ip6tables -w ${TL} -A OUTPUT -j DROP
ip6tables -w ${TL} -A FORWARD -j DROP

# Setup the direct network
ip addr add ${GW_DIRIF_IP} dev ${GW_DIRIF}
ip link set ${GW_DIRIF} mtu ${WG_MTU}
ip link set ${GW_DIRIF} up
ip route add ${HS_DIRIF_IP} dev ${GW_DIRIF} src ${GW_DIRIF_IP}

# Setup the external network
ip link add name ${GW_EXTIF} type bridge 2>/dev/null
ip link set ${GW_MIDIF} master ${GW_EXTIF}
ip link set ${GW_EXTIF} address ${EXT_MACADDR}
ip addr add ${EXT_NET} dev ${GW_EXTIF}
ip link set ${GW_MIDIF} up
ip link set ${GW_EXTIF} up
ip route add default via ${EXT_GATEWAY}

# Setup up the facade interface
ip link set ${OVS_FACIF} mtu ${ACC_MTU}
ip link set ${OVS_FACIF} up

# Setup WireGuard
${BIN_DIR}/run_wireguard.sh

# Start the DNS server
${BIN_DIR}/run_dns_server.sh start

# Start Open vSwitch
${BIN_DIR}/run_ovs.sh

# Setup the access network
ip addr add ${GATEWAY_NET} dev ${OVS_BR}
ip link set ${OVS_BR} mtu ${ACC_MTU}
ip link set ${OVS_BR} up
