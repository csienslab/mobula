#!/usr/bin/env bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd -P)
source ${BASE_DIR}/constants.conf

exec ip netns exec ${NS_NAME} ovs-vsctl --db="unix:${OVS_DBSOCK}" "$@"
