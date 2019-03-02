#!/usr/bin/env bash

export BASEDIR=$(cd "$(dirname "$0")"; pwd -P)
PID_FILE=${BASEDIR}/dnsmasq.pid

if [ -f ${PID_FILE} ]; then
  PID=$(cat ${PID_FILE})
  while $(kill -9 ${PID}); do
    sleep 1
  done
  rm -f ${PID_FILE}
fi

dnsmasq -x ${PID_FILE} --conf-file=${BASEDIR}/dnsmasq.conf --addn-hosts=${BASEDIR}/hosts --resolv-file=${BASEDIR}/resolv.conf --log-facility=/dev/null
