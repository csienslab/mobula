#!/usr/bin/env bash

BASEDIR=$(cd "$(dirname "$0")"; pwd -P)
source ${BASEDIR}/constants.conf
PID_FILE="${RUN_DIR}/dnsmasq.pid"

if [ -f "${PID_FILE}" ]; then
  PID=$(cat "${PID_FILE}")
  while kill -TERM "${PID}"; do
    sleep 1
  done
  rm -f "${PID_FILE}"
fi

ip netns exec ${NS_NAME} dnsmasq -x "${PID_FILE}" \
    --conf-file="${BASEDIR}/dnsmasq.conf" \
    --addn-hosts="${BASEDIR}/hosts" \
    --resolv-file="${BASEDIR}/resolv.conf" \
    --log-facility=/dev/null
