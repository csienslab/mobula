#!/usr/bin/env bash

source ./constants.conf

ovs-vsctl del-br ${OVS_BR}
ovs-vsctl add-br ${OVS_BR}
ovs-vsctl add-port ${OVS_BR} ${OVS_INTIF}
ovs-vsctl add-port ${OVS_BR} ${OVS_VETH}
