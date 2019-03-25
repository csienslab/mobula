#!/usr/bin/env bash

BASE_DIR="{{install_dir}}"
source ${BASE_DIR}/etc/constants.conf
source ${BASE_DIR}/etc/network.conf

export OVS_LOGDIR="${LOG_DIR}/openvswitch"
export OVS_RUNDIR="${RUN_DIR}/openvswitch"
export OVS_DBDIR="${ETC_DIR}/openvswitch"
export OVS_SYSCONFDIR="${ETC_DIR}"

${OVS_CTL} --system-id=random --db-sock="${OVS_DBSOCK}" start

${BIN_DIR}/ovs_vsctl_wrapper.sh --may-exist add-br "${OVS_BR}"
${BIN_DIR}/ovs_vsctl_wrapper.sh --may-exist add-port "${OVS_BR}" "${OVS_FACIF}"
