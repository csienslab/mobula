#!/usr/bin/env bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd -P)
source ${BASE_DIR}/constants.conf
PID_FILE="${RUN_DIR}/dnsmasq.pid"

if [ -f "${PID_FILE}" ] && [ "$1" = "restart" ]; then
  PID=$(cat "${PID_FILE}")
  while kill -TERM "${PID}"; do
    sleep 1
  done
fi

ip netns exec ${NS_NAME} dnsmasq -x "${PID_FILE}" \
    --conf-file="${DATA_DIR}/dnsmasq.conf" \
    --addn-hosts="${DATA_DIR}/hosts" \
    --resolv-file="${DATA_DIR}/resolv.conf" \
    --log-facility=/dev/null
