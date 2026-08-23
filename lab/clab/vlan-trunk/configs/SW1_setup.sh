#!/bin/bash
# SW1 - 2 台 switch 中的第一台
# 端口分配：
#   eth1 → host1 (VLAN 10 access)
#   eth2 → host2 (VLAN 10 access)
#   eth3 → SW2 (trunk, 允许 VLAN 10, 20)
#
# 用 Linux bridge + VLAN 子接口实现：
#   - 创建 bridge br0
#   - 创建 VLAN 10 子接口 br0.10
#   - 把 access port 加入 br0（access mode，untagged VLAN 10）
#   - trunk port 加 802.1Q tag

set -e

# 等接口起来
for i in 1 2 3 4 5; do
  if ip link show eth1 >/dev/null 2>&1 && ip link show eth2 >/dev/null 2>&1 && ip link show eth3 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# 创建 bridge
ip link add br0 type bridge
ip link set br0 up

# 创建 VLAN 10 和 VLAN 20 子接口（用来配 IP 可选，这里只做 L2，不配 IP）
ip link add link br0 name br0.10 type vlan id 10
ip link add link br0 name br0.20 type vlan id 20
ip link set br0.10 up
ip link set br0.20 up

# 配置 access port: eth1 (VLAN 10) 和 eth2 (VLAN 10)
# Access port 收到 untagged 帧 → 自动加 VLAN 10 tag → 进 bridge
# Access port 发送 tagged 帧 → 去掉 VLAN 10 tag → 发出 untagged 帧
for port in eth1 eth2; do
  # 创建 VLAN 10 的子接口
  ip link add link $port name ${port}.10 type vlan id 10
  ip link set ${port}.10 master br0
  ip link set ${port}.10 up
  # access port 本身加进 bridge（不带 tag）
  ip link set $port master br0
  ip link set $port up
  # 设 PVID（port VLAN ID），untagged 帧归到 VLAN 10
  bridge vlan add dev $port vid 10 pvid untagged
done

# 配置 trunk port: eth3 → SW2
# Trunk 保留所有 VLAN tag 透传
ip link set eth3 master br0
ip link set eth3 up
bridge vlan add dev eth3 vid 10
bridge vlan add dev eth3 vid 20

echo "SW1 ready: 2 access (VLAN 10) + 1 trunk (VLAN 10, 20)"
bridge vlan show
