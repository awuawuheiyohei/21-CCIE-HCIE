#!/bin/bash
# R4 - 配 IP + iBGP peer (R3) 的 loopback 路由
sleep 2
ip link set lo up
ip route replace 3.3.3.3/32 via 10.0.34.3
echo "R4 ready"
