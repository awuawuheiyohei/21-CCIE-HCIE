#!/bin/bash
# host1 - Area 1 内部测试主机
# IP: 10.0.34.2/30, gateway 10.0.34.1 (R3)
# Standard /30 (不是 broadcast): 10.0.34.1 + 10.0.34.2

set -e

for i in 1 2 3 4 5; do
  if ip link show eth1 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

ip addr add 10.0.34.2/30 dev eth1
ip link set eth1 up
ip link set lo up

# 用 replace 避免 "RTNETLINK: File exists"（docker 已给 default 路由）
ip route replace default via 10.0.34.1

echo "host1 ready: 10.0.34.2/30"
