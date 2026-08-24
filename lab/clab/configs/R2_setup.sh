#!/bin/bash
# R2 setup - 等接口起来 + 强补 3.3.3.3 / 10.0.34.0 路由
# （绕开 frr 8.4 ABR self-summary 抑制 bug：R2 自己起源 Summary 3.3.3.3/32 进 area 0，
#  frr 把 R2 从 R3 收到的 intra-area 3.3.3.3 标 rejected，R2 kernel 路由表没这条，
#  包到 R2 被 drop。补 static route 强制走 R3）
sleep 2
ip link set lo up
ip route replace 3.3.3.3/32 via 10.0.23.3
ip route replace 10.0.34.0/30 via 10.0.23.3
echo "R2 ready (with static routes for 3.3.3.3 and 10.0.34.0)"

