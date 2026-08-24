#!/bin/bash
# R1 - 配 IP + 配到 iBGP peer (R2) 的 loopback 路由
# iBGP over loopback 必须能 ping 通对方 lo，否则 BGP session 起不来
sleep 2
ip link set lo up
ip route replace 2.2.2.2/32 via 10.0.12.2
echo "R1 ready"
