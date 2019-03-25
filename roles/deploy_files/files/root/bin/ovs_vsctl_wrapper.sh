#!/usr/bin/env bash

BASE_DIR="{{install_dir}}"
source ${BASE_DIR}/etc/constants.conf

exec ip netns exec ${NS_NAME} ovs-vsctl --db="unix:${OVS_DBSOCK}" "$@"
