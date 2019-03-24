#!/usr/bin/env bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd -P)
source ${BASE_DIR}/constants.conf
source ${BASE_DIR}/network.conf

ip netns exec ${NS_NAME} wg-quick down "${DATA_DIR}/${GW_WGIF}.conf"
ip netns exec ${NS_NAME} wg-quick up "${DATA_DIR}/${GW_WGIF}.conf"
