#!/usr/bin/env bash

BASE_DIR="{{install_dir}}"
source ${BASE_DIR}/etc/constants.conf
source ${BASE_DIR}/etc/network.conf

# Clean the existed interfaces and namespaces
ip link del ${GW_MIDIF} 2>/dev/null
ip link del ${HS_EXTIF} 2>/dev/null
ip link del ${OVS_FACIF} 2>/dev/null
ip link del ${HS_FACIF} 2>/dev/null
ip link del ${GW_DIRIF} 2>/dev/null
ip link del ${HS_DIRIF} 2>/dev/null

# Try to create the namespace
ip netns add ${NS_NAME} 2>/dev/null

# Setup the direct network
ip link add ${GW_DIRIF} type veth peer name ${HS_DIRIF}
ip link set ${GW_DIRIF} netns ${NS_NAME}
ip addr add ${HS_DIRIF_IP} dev ${HS_DIRIF}
ip link set ${HS_DIRIF} mtu ${WG_MTU}
ip link set ${HS_DIRIF} up
ip route add ${GW_DIRIF_IP} dev ${HS_DIRIF} src ${HS_DIRIF_IP}

# Duplicate the external interface
ip link add ${HS_EXTIF} type veth peer name ${GW_MIDIF}
# Move the middle interface into the namespace
ip link set ${GW_MIDIF} netns ${NS_NAME}

# Setup the facade interface
ip link add ${HS_FACIF} type veth peer name ${OVS_FACIF}
ip link set ${OVS_FACIF} netns ${NS_NAME}
ip link set ${HS_FACIF} mtu ${ACC_MTU}
ip link set ${HS_FACIF} up

# Setup the gateway
ip netns exec ${NS_NAME} ${BIN_DIR}/gateway.sh

# Setup the routing rules for the direct network
ip route add table 10 default via ${GW_DIRIF_IP} dev ${HS_DIRIF}
# Route all traffic from the direct ip to the direct network
ip rule add from ${HS_DIRIF_IP} table 10 priority 10
ip rule add to ${WG_SUBNET} table 10 priority 11
# Flush routing cache
ip route flush cache

{% if no_net_hook is not defined %}
# Try to get the external interface
${BIN_DIR}/interface_hook.sh ${EXT_IF}
{% endif %}
