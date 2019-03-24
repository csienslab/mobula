#!/usr/bin/env bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd -P)
source ${BASE_DIR}/constants.conf
source ${BASE_DIR}/network.conf

export OVS_LOGDIR="${LOG_DIR}/openvswitch"
export OVS_RUNDIR="${RUN_DIR}/openvswitch"
export OVS_DBDIR="${ETC_DIR}/openvswitch"
export OVS_SYSCONFDIR="${ETC_DIR}"

mkdir -p ${OVS_LOGDIR} 2>/dev/null
mkdir -p ${OVS_RUNDIR} 2>/dev/null
mkdir -p ${OVS_DBDIR} 2>/dev/null
mkdir -p ${OVS_SYSCONFDIR} 2>/dev/null

${OVS_CTL} --system-id=random --db-sock="${OVS_DBSOCK}" start

${BASE_DIR}/ovs_vsctl_wrapper.sh --may-exist add-br "${OVS_BR}"
${BASE_DIR}/ovs_vsctl_wrapper.sh --may-exist add-port "${OVS_BR}" "${OVS_FACIF}"