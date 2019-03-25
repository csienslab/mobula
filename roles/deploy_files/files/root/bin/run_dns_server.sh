#!/usr/bin/env bash

BASE_DIR="{{install_dir}}"
source ${BASE_DIR}/etc/constants.conf
PID_FILE="${RUN_DIR}/dnsmasq.pid"

if [ -f "${PID_FILE}" ] && [ "$1" = "restart" ]; then
  PID=$(cat "${PID_FILE}")
  while kill -TERM "${PID}"; do
    sleep 1
  done
fi

ip netns exec ${NS_NAME} dnsmasq -x "${PID_FILE}" \
    --conf-file="${ETC_DIR}/dnsmasq/dnsmasq.conf" \
    --addn-hosts="${ETC_DIR}/dnsmasq/hosts" \
    --resolv-file="${ETC_DIR}/dnsmasq/resolv.conf" \
    --log-facility=/dev/null
