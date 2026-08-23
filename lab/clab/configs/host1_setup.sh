#!/bin/bash
# host1 setup - 配 IP + 默认路由
# IP: 10.0.34.4/30, gateway 10.0.34.3 (R3)

# 等待接口 up
for i in 1 2 3 4 5; do
  if ip link show eth1 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# 配 IP
ip addr add 10.0.34.4/30 dev eth1
ip link set eth1 up
ip link set lo up

# 默认路由到 R3
ip route add default via 10.0.34.3

echo "host1 ready: 10.0.34.4/30"
