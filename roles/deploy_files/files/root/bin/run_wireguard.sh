#!/usr/bin/env bash

BASE_DIR="{{install_dir}}"
source ${BASE_DIR}/etc/constants.conf
source ${BASE_DIR}/etc/network.conf

ip netns exec ${NS_NAME} wg-quick down "${ETC_DIR}/wireguard/${GW_WGIF}.conf"
ip netns exec ${NS_NAME} wg-quick up "${ETC_DIR}/wireguard/${GW_WGIF}.conf"
