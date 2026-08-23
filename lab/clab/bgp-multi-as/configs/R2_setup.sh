#!/bin/bash
# R2 - 配 IP + 配到 R1 的 loopback 路由（让 R2 能 ping 通 1.1.1.1）
sleep 2
ip link set lo up

# R1 跟 R2 在同一物理网段（10.0.12.0/30），所以不需要静态路由
# R1 也用 2.2.2.2 (R2 的 loopback) 建邻居
# 但 R1 自己的 loopback 1.1.1.1 需要 R2 能学到
# 实际：iBGP 邻居要先能 ping 通对方 loopback
# R2 自己的 loopback 不需要 R1 学（但 R1 用 R2 的 loopback 建邻居）
echo "R2 ready"
