#!/usr/bin/env bash

BASEDIR=$(cd "$(dirname "$0")"; pwd -P)
source ${BASEDIR}/constants.conf

exec ip netns exec ${NS_NAME} ovs-vsctl --db="unix:${OVS_DBSOCK}" "$@"
