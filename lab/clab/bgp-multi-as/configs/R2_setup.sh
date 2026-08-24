#!/bin/bash
# R2 - 配 IP + iBGP/eBGP 跨 AS 转发路径上需要的 loopback 路由
sleep 2
ip link set lo up
# iBGP peer R1 lo
ip route replace 1.1.1.1/32 via 10.0.12.1
# eBGP peer R3 通告 R4 的 lo (4.4.4.4) 时，R2 需要能转发到 R4
# R3 自己的 eBGP next-hop 是 10.0.23.3（直连），但 4.4.4.4 是 R4 的 lo，要 R2 走 10.0.23.3 → R3
ip route replace 4.4.4.4/32 via 10.0.23.3
echo "R2 ready"
