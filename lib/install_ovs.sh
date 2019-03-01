#!/usr/bin/env bash

source ./constants.conf

ovs-vsctl del-br ${OVS_BR}
ovs-vsctl add-br ${OVS_BR}
ovs-vsctl set bridge ${OVS_BR} stp_enable=true
ovs-vsctl add-port ${OVS_BR} ${OVS_INTIF}
ovs-vsctl add-port ${OVS_BR} ${OVS_VETH}
