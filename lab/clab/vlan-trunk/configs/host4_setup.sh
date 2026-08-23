#!/bin/bash
# host4 - VLAN 20, IP 10.20.0.14/24 (跟 host1/2/3 不同 VLAN)
set -e

for i in 1 2 3 4 5; do
  if ip link show eth1 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

ip addr add 10.20.0.14/24 dev eth1
ip link set eth1 up
ip link set lo up

echo "host4 ready: 10.20.0.14/24 (VLAN 20)"
