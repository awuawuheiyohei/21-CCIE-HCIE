#!/bin/bash
# host1 - VLAN 10, IP 10.10.0.11/24
set -e

for i in 1 2 3 4 5; do
  if ip link show eth1 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# 配 IP
ip addr add 10.10.0.11/24 dev eth1
ip link set eth1 up
ip link set lo up

echo "host1 ready: 10.10.0.11/24 (VLAN 10)"
