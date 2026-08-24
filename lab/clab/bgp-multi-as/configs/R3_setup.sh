#!/bin/bash
# R3 - 配 IP + iBGP peer (R4) 的 loopback 路由
sleep 2
ip link set lo up
ip route replace 4.4.4.4/32 via 10.0.34.4
echo "R3 ready"
