#!/usr/bin/env bash

BASE_DIR="{{install_dir}}"
source ${BASE_DIR}/etc/constants.conf
source ${BASE_DIR}/etc/network.conf

if [ "$1" != ${EXT_IF} ]; then
  exit 0
fi

# Try to create the namespace
ip netns add ${NS_NAME} 2>/dev/null

# Move and bind the external interface
ip link set "$1" netns ${NS_NAME}
ip -n ${NS_NAME} link add name ${GW_EXTIF} type bridge 2>/dev/null
ip -n ${NS_NAME} link set "$1" master ${GW_EXTIF}
ip -n ${NS_NAME} link set "$1" up
